##----------------------------------------------------------------------------
## A real Try Catch Block Implementation Using Perl Filter - ~/lib/Nice/Try.pm
## Version v0.1.5
## Copyright(c) 2020 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <@gabriel.tokyo.deguest.jp>
## Created 2020/05/17
## Modified 2020/09/13
## 
##----------------------------------------------------------------------------
package Nice::Try;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use PPI;
    use Filter::Util::Call;
    use Scalar::Util;
    use List::Util ();
    # use Devel::Confess;
    our $VERSION = 'v0.1.5';
    our $ERROR;
    our( $CATCH, $DIED, $EXCEPTION, $FINALLY, $HAS_CATCH, @RETVAL, $SENTINEL, $TRY, $WANTARRAY );
}

## Taken from Try::Harder version 0.005
our $SENTINEL = bless( {} => __PACKAGE__ . '::SENTINEL' );

sub import
{
    my( $this, @arguments ) = @_ ;
    my $hash = { @arguments };
    $hash->{debug} = 0 if( !CORE::exists( $hash->{debug} ) );
    $hash->{no_filter} = 0 if( !CORE::exists( $hash->{no_filter} ) );
    $hash->{debug_code} = 0 if( !CORE::exists( $hash->{debug_code} ) );
    filter_add( bless( $hash => ( ref( $this ) || $this ) ) );
}

sub unimport
{       
    filter_del();
}

sub filter
{
    my( $self ) = @_ ;
    my( $status, $last_line );
    my $line = 0;
    my $code = '';
    if( $self->{no_filter} )
    {
        filter_del();
        $status = 1;
        $self->_message( 3, "Skiping filtering." );
        return( $status );
    }
    while( $status = filter_read() )
    {
        return( $status ) if( $status < 0 );
        $line++;
        if( /^__(?:DATA|END)__/ )
        {
            $last_line = $_;
            last;
        }
        $code .= $_;
        $_ = '';
    }
    return( $line ) if( !$line );
    unless( $status < 0 )
    {
        ## $self->_message( 5, "Processing at line $line code:\n$code" );
        my $doc = PPI::Document->new( \$code, readonly => 1 ) || die( "Unable to parse: ", PPI::Document->errstr, "\n$code\n" );
        if( $doc = $self->_parse( $doc ) )
        {
            $_ = $doc->serialize;
            # $doc->save( "./dev/debug-parsed.pl" );
            # $status = 1;
        }
        ## Rollback
        else
        {
            # $self->_message( 5, "Nothing found, restoring code to '$code'" );
            $_ = $code;
#             $status = -1;
#             filter_del();
        }
        if( CORE::length( $last_line ) )
        {
            $_ .= $last_line;
        }
    }
    unless( $status <= 0 )
    {
        while( $status = filter_read() )
        {
            return( $status ) if( $status < 0 );
            $line++;
        }
    }
    # $self->_message( 3, "Returning status '$line' with \$_ set to '$_'." );
    if( $self->{debug_file} )
    {
        if( my $fh = IO::File->new( ">$self->{debug_file}" ) )
        {
            $fh->binmode( ':utf8' );
            $fh->print( $_ );
            $fh->close;
        }
    }
    # filter_del();
    return( $line );
}

sub _browse
{
    my $self = shift( @_ );
    my $elem = shift( @_ );
    my $level = shift( @_ ) || 0;
    $self->_message( 4, "Checking code '$elem'." );
    $self->_messagef( 4, "PPI element of class %s has children property '%s'.", $elem->class, $elem->{children} );
    return if( !$elem->children );
    foreach my $e ( $elem->elements )
    {
        printf( STDERR "%sElement: [%d] class %s, value %s\n", ( '.' x $level ), $e->line_number, $e->class, $e->content );
        if( $e->can('children') && $e->children )
        {
            $self->_browse( $e, $level + 1 );
        }
    }
}

sub _error
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $txt = join( '', map( ref( $_ ) eq 'CODE' ? $_->() : $_, @_ ) );
        $txt =~ s/\v+$//g;
        $ERROR = $txt;
        CORE::warn( "$txt\n" ) if( warnings::enabled );
        return;
    }
    return( $ERROR );
}

sub _message
{
    my $self = shift( @_ );
    my $level = $_[0] =~ /^\d+$/ ? shift( @_ ) : 0;
    return if( $self->{debug} < $level );
    my @data = @_;
    $stackFrame = 0;
    my( $pkg, $file, $line, @otherInfo ) = caller( $stackFrame );
    my $sub = ( caller( $stackFrame + 1 ) )[3];
    my $sub2 = substr( $sub, rindex( $sub, '::' ) + 2 );
    my $txt = "${pkg}::${sub2}( $self ) [$line]: " . join( '', map( ref( $_ ) eq 'CODE' ? $_->() : $_, @data ) );
    $txt    =~ s/\n$//gs;
    $txt = '## ' . join( "\n## ", split( /\n/, $txt ) );
    CORE::print( STDERR $txt, "\n" );
}

sub _messagef
{
    my $self = shift( @_ );
    my $level = $_[0] =~ /^\d+$/ ? shift( @_ ) : 0;
    return if( $self->{debug} < $level );
    my @data = @_;
    $stackFrame = 0;
    my $fmt = shift( @data );
    my( $pkg, $file, $line, @otherInfo ) = caller( $stackFrame );
    my $sub = ( caller( $stackFrame + 1 ) )[3];
    my $sub2 = substr( $sub, rindex( $sub, '::' ) + 2 );
    my $txt = "${pkg}::${sub2}( $self ) [$line]: " . sprintf( $fmt, map( ref( $_ ) eq 'CODE' ? $_->() : $_, @data ) );
    $txt    =~ s/\n$//gs;
    $txt = '## ' . join( "\n## ", split( /\n/, $txt ) );
    CORE::print( STDERR $txt, "\n" );
}

sub _parse
{
    my $self = shift( @_ );
    my $elem = shift( @_ );
    if( !Scalar::Util::blessed( $elem ) || !$elem->isa( 'PPI::Node' ) )
    {
        return( $self->_error( "Element provided to parse is not a PPI::Node object" ) );
    }
    my $ref = $elem->find(sub
    {
        my( $top, $this ) = @_;
        return( $this->class eq 'PPI::Statement' && substr( $this->content, 0, 3 ) eq 'try' );
    });
    return( $self->_error( "Failed to find any try-catch clause: $@" ) ) if( !defined( $ref ) );
    $self->_messagef( 4, "Found %d match(es)", scalar( @$ref ) );
    return if( !scalar( @$ref ) );
    
    ## 2020-09-13: PPI will return 2 or more consecutive try-catch block as 1 statement
    ## It does not tell them apart, so we need to post process the result to effectively search within for possible for other try-catch blocks and update the @$ref array consequently
    ## Array to contain the new version of the $ref array.
    my $alt_ref = [];
    $self->_message( 3, "Checking for consecutive try-catch blocks in results found by PPI" );
    foreach my $this ( @$ref )
    {
        my( @block_children ) = $this->children;
        next if( !scalar( @block_children ) );
        my $tmp_ref = [];
        ## to contain all the nodes to move
        my $tmp_nodes = [];
        my $prev_sib = $block_children[0];
        push( @$tmp_nodes, $prev_sib );
        my $sib;
        while( $sib = $prev_sib->next_sibling )
        {
            ## We found a try-catch block. Move the buffer to $alt_ref
            if( $sib->class eq 'PPI::Token::Word' && $sib->content eq 'try' )
            {
                ## Look ahead for a block...
                my $next = $sib->snext_sibling;
                if( $next && $next->class eq 'PPI::Structure::Block' )
                {
                    $self->_message( 3, "Found consecutive try-block." );
                    ## Push the previous statement $st to the stack $alt_ref
                    $self->_messagef( 3, "Saving previous %d nodes collected.", scalar( @$tmp_nodes ) );
                    push( @$tmp_ref, $tmp_nodes );
                    $tmp_nodes = [];
                }
            }
            push( @$tmp_nodes, $sib );
            $prev_sib = $sib;
        }
        $self->_messagef( 3, "Saving last %d nodes collected.", scalar( @$tmp_nodes ) );
        push( @$tmp_ref, $tmp_nodes );
        $self->_messagef( 3, "Found %d try-catch block(s) in initial PPI result.", scalar( @$tmp_ref ) );
        ## If we did find consecutive try-catch blocks, we add each of them after the nominal one and remove the nominal one after. The nominal one should be empty by then
        if( scalar( @$tmp_ref ) > 1 )
        {
            my $last_obj = $this;
            my $spaces = [];
            foreach my $arr ( @$tmp_ref )
            {
                $self->_messagef( 3, "Adding statement block with %d children after '$last_obj'", scalar( @$arr ) );
                ## Get the trailing insignificant elements at the end of the statement and move them out of the statement
                my $insignificants = [];
                while( scalar( @$arr ) > 0 )
                {
                    my $o = $arr->[-1];
                    ## $self->_message( 3, "Checking trailing object with class '", $o->class, "' and value '$o'" );
                    last if( $o->class eq 'PPI::Structure::Block' );
                    unshift( @$insignificants, pop( @$arr )->remove );
                }
                ## $self->_messagef( 3, "%d insignificant objects found.", scalar( @$insignificants ) );
                
                my $st = PPI::Statement->new;
                ## $self->_messagef( 3, "Adding the updated statement objects with %d children.", scalar( @$arr ) );
                foreach my $o ( @$arr )
                {
                    ## We remove the object from its parent, because, as per the documentation, an object can only have one parent
                    ## Without removing, this would simply fail. The object added would be empty.
                    my $old = $o->remove || die( "Unable to remove element '$o'\n" );
                    $st->add_element( $old );
                }
                my $err = '';
                ## $self->_messagef( 3, "Adding the statement object after last object of class '%s'.", $last_obj->class );
                my $rc = $last_obj->insert_after( $st );
                if( !defined( $rc ) )
                {
                    $err = sprintf( 'Object to be added after last try-block statement must be a PPI::Element. Class provided is \"%s\".', $st->class );
                }
                elsif( !$rc )
                {
                    $err = sprintf( "Object of class \"%s\" could not be added after object of class '%s': '$last_obj'.", $st->class, $last_obj->class );
                }
                $last_obj = $st;
                if( scalar( @$insignificants ) )
                {
                    ## $self->_messagef( 3, "Adding %d trailing insignificant objects after last element of class '%s'", scalar( @$insignificants ), $last_obj->class );
                    foreach my $o ( @$insignificants )
                    {
                        ## $self->_messagef( 3, "Adding trailing insignificant object of class '%s' after last element of class '%s'", $o->class, $last_obj->class );
                        $last_obj->insert_after( $o ) ||
                        warn( "Failed to insert object of class '", $o->class, "' before last object of class '", $st->class, "'\n" );
                        $last_obj = $o;
                    }
                }
                die( $err ) if( length( $err ) );
                push( @$alt_ref, $st );
            }
            my $parent = $this->parent;
            ## Completely destroy it; it is now replaced by our updated code
            $this->delete;
        }
        else
        {
            push( @$alt_ref, $this );
        }
    }
    $self->_messagef( 3, "Results found increased from %d to %d results.", scalar( @$ref ), scalar( @$alt_ref ) );
    @$ref = @$alt_ref if( scalar( @$alt_ref ) > scalar( @$ref ) );
    
    ## $self->_message( 3, "Script code is now:\n'$elem'" );
    
    foreach my $this ( @$ref )
    {
        $self->_browse( $this ) if( $self->{debug} >= 5 );
        my $element_before_try = $this->previous_sibling;
        my $try_block_ref = [];
        ## Contains the finally block reference
        my $fin_block_ref = [];
        my $nodes_to_replace = [];
        my $catch_def = [];
        ## Replacement data
        my $repl = [];
        my $catch_repl = [];
        
        ## There is a weird bug in PPI that I have searched but could not find
        ## If I don't attempt to stringify, I may end up with a PPI::Statement object that has no children as an array reference
        my $ct = "$this";
        ## $self->_message( 3, "Checking sibling elements for '$ct'" );
        my( @block_children ) = $this->children;
        next if( !scalar( @block_children ) );
        my $prev_sib = $block_children[0];
        push( @$nodes_to_replace, $prev_sib );
        my( $inside_catch, $inside_finally );
        my $temp = {};
        ## Buffer of nodes found in between blocks
        my $buff = [];
        ## Temporary new line counter between try-catch block so we can reproduce it and ensure proper reporting of error line
        my $nl_counter = 0;
        my $sib;
        while( $sib = $prev_sib->next_sibling )
        {
            ## $self->_messagef( 3, "Try sibling at line %d with class '%s': '%s'", $sib->line_number, $sib->class, $sib->content );
            if( !scalar( @$try_block_ref ) )
            {
                ## $self->_message( 3, "\tWorking on the initial try block." );
                if( $sib->class eq 'PPI::Structure::Block' &&
                    substr( "$sib", 0, 1 ) eq "\{" &&
                    substr( "$sib", -1, 1 ) eq "\}" )
                {
                    $temp->{block} = $sib;
                    push( @$try_block_ref, $temp );
                    $temp = {};
                    if( scalar( @$buff ) )
                    {
                        push( @$nodes_to_replace, @$buff );
                        $buff = [];
                    }
                    push( @$nodes_to_replace, $sib );
                }
                elsif( $sib->class eq 'PPI::Token::Whitespace' && $sib->content =~ /\v+/ )
                {
                    ## $self->_messagef( 4, "\tTry -> Found open new line at line %d", $sib->line_number );
                    $temp->{open_curly_nl}++;
                    push( @$buff, $sib );
                }
                ## We skip anything else until we find that try block
                else
                {
                    push( @$buff, $sib );
                    $prev_sib = $sib;
                    next;
                }
            }
            elsif( $sib->class eq 'PPI::Token::Word' && $sib->content eq 'catch' )
            {
                $inside_catch++;
                if( scalar( @$buff ) )
                {
                    push( @$nodes_to_replace, @$buff );
                    $buff = [];
                }
                push( @$nodes_to_replace, $sib );
            }
            elsif( $inside_catch )
            {
                ## $self->_message( 3, "\tWorking on a catch block." );
                ## This is the catch list as in catch( $e ) or catch( Exception $e )
                if( $sib->class eq 'PPI::Structure::List' )
                {
                    $temp->{var} = $sib;
                    push( @$nodes_to_replace, $sib );
                }
                elsif( $sib->class eq 'PPI::Structure::Block' )
                {
                    $temp->{block} = $sib;
                    if( scalar( @$catch_def ) )
                    {
                        $catch_def->[-1]->{close_curly_nl} = $nl_counter;
                    }
                    else
                    {
                        $try_block_ref->[-1]->{close_curly_nl} = $nl_counter;
                    }
                    $nl_counter = 0;
                    push( @$catch_def, $temp );
                    $temp = {};
                    $inside_catch = 0;
                    push( @$nodes_to_replace, $sib );
                }
                elsif( $sib->class eq 'PPI::Token::Whitespace' && $sib->content =~ /\v+/ )
                {
                    ## $self->_messagef( 4, "\tCatch -> Found open new line at line %d", $sib->line_number );
                    $temp->{open_curly_nl}++;
                    push( @$nodes_to_replace, $sib );
                }
                else
                {
                    push( @$nodes_to_replace, $sib );
                }
            }
            elsif( $sib->class eq 'PPI::Token::Word' && $sib->content eq 'finally' )
            {
                $inside_finally++;
                if( scalar( @$buff ) )
                {
                    push( @$nodes_to_replace, @$buff );
                    $buff = [];
                }
                push( @$nodes_to_replace, $sib );
            }
            elsif( $inside_finally )
            {
                ## $self->_message( 3, "\tWorking on a finally block." );
                ## We could ignore it, but it is best to let the developer know in case he/she counts on it somehow
                if( $sib->class eq 'PPI::Structure::List' )
                {
                    die( sprintf( "the finally block does not accept any list parameters at line %d\n", $sib->line_number ) );
                }
                elsif( $sib->class eq 'PPI::Structure::Block' )
                {
                    $temp->{block} = $sib;
                    if( scalar( @$fin_block_ref ) )
                    {
                        die( sprintf( "There can only be one finally block at line %d\n", $sib->line_number ) );
                    }
                    elsif( scalar( @$catch_def ) )
                    {
                        $catch_def->[-1]->{close_curly_nl} = $nl_counter;
                    }
                    else
                    {
                        $try_block_ref->[-1]->{close_curly_nl} = $nl_counter;
                    }
                    $nl_counter = 0;
                    push( @$fin_block_ref, $temp );
                    $temp = {};
                    $inside_finally = 0;
                    push( @$nodes_to_replace, $sib );
                }
                elsif( $sib->class eq 'PPI::Token::Whitespace' && $sib->content =~ /\v+/ )
                {
                    ## $self->_messagef( 4, "\tFinally -> Found open new line at line %d", $sib->line_number );
                    $temp->{open_curly_nl}++;
                    push( @$nodes_to_replace, $sib );
                }
                else
                {
                    push( @$nodes_to_replace, $sib );
                }
            }
            ## Check for new lines after closing blocks. The ones before, we can account for them in each section above
            ## We could have } catch {
            ## or
            ## }
            ## catch {
            ## etc.
            ## This could also be new lines following the last catch block
            elsif( $sib->class eq 'PPI::Token::Whitespace' && $sib->content =~ /\v+/ )
            {
                ## $self->_messagef( 4, "Between -> Found closing new line at line %d", $sib->line_number );
                $nl_counter++;
                push( @$buff, $sib );
            }
            else
            {
                push( @$buff, $sib );
            }
            $prev_sib = $sib;
        }
        
        my $has_catch_clause = scalar( @$catch_def ) > 0 ? 1 : 0;
        
        ## Prepare the finally block, if any, and add it below at the appropriate place
        my $fin_block = '';
        if( scalar( @$fin_block_ref ) )
        {
            my $fin_def = $fin_block_ref->[0];
            ## my $finally_block = $fin_def->{block}->content;
            my $finally_block = $self->_serialize( $fin_def->{block} );
            $finally_block =~ s/^\{[[:blank:]]*|[[:blank:]]*\}$//gs;
            $fin_block = <<EOT;
CORE::local \$Nice::Try::FINALLY = Nice\::Try\::ScopeGuard->_new(sub __FINALLY_OPEN_NL__{ __BLOCK_PLACEHOLDER__ __FINALLY__CLOSE_NL__}, \@_);
EOT
            $fin_block =~ s/\n/ /gs unless( $self->{debug_code} );
            $fin_block =~ s/__BLOCK_PLACEHOLDER__/$finally_block/gs;
            if( $fin_def->{open_curly_nl} )
            {
                $fin_block =~ s/__FINALLY_OPEN_NL__/"\n" x $fin_def->{open_curly_nl}/gex;
            }
            else
            {
                $fin_block =~ s/__FINALLY_OPEN_NL__//gs;
            }
            if( $fin_def->{close_curly_nl} )
            {
                $fin_block =~ s/__FINALLY__CLOSE_NL__/"\n" x $fin_def->{close_curly_nl}/gex;
            }
            else
            {
                $fin_block =~ s/__FINALLY__CLOSE_NL__//gs;
            }
        }

        ## Found any try block at all?
        if( scalar( @$try_block_ref ) )
        {
            ## $self->_message( 3, "Original code to remove is:\n", join( '', @$nodes_to_replace ) );
            ## $self->_message( 3, "Try definition: ", $try_block_ref->[0]->{block}->content );
            ## $self->_messagef( 3, "%d catch clauses found", scalar( @$catch_def ) );
            foreach my $c ( @$catch_def )
            {
                ## $self->_message( 3, "Catch variable assignment: ", $c->{var} );
                ## $self->_message( 3, "Catch block: ", $c->{block} );
            }
            my $try_def = $try_block_ref->[0];
            ## $self->_messagef( 3, "Try new lines before block: %d, after block %d", $try_def->{open_curly_nl}, $try_def->{close_curly_nl} );
            
            ## Checking for embedded try-catch
            ## $self->_message( 4, "Checking for embedded try-catch in ", $try_def->{block} );
            if( my $emb = $self->_parse( $try_def->{block} ) )
            {
                $try_def->{block} = $emb;
            }
                        
            ## my $try_block = $try_def->{block}->content;
            my $try_block = $self->_serialize( $try_def->{block} );
            $try_block =~ s/^\{[[:blank:]]*|[[:blank:]]*\}$//gs;
            
            my $try_sub = <<EOT;
CORE::local \$Nice::Try::TRY = CORE::sub
{
    CORE::do __TRY_OPEN_NL__{ __BLOCK_PLACEHOLDER__ };__TRY__CLOSE_NL__
    CORE::return( \$Nice::Try::SENTINEL );
};
CORE::local ( \$Nice::Try::EXCEPTION, \$Nice::Try::DIED, \@Nice::Try::RETVAL );
__FINALLY_BLOCK__ CORE::local \$Nice::Try::HAS_CATCH = $has_catch_clause;
CORE::local \$Nice::Try::WANTARRAY = CORE::wantarray;
{
    CORE::local \$\@;
    CORE::eval 
    {
        if( \$Nice::Try::WANTARRAY ) 
        {
            \@Nice::Try::RETVAL = &\$Nice::Try::TRY;
        }
        elsif( defined( \$Nice::Try::WANTARRAY ) ) 
        {
            \$Nice::Try::RETVAL[0] = &\$Nice::Try::TRY;
        }
        else 
        {
            &\$Nice::Try::TRY;
        }
    };
    \$Nice::Try::DIED = CORE::length( \$\@ ) ? 1 : 0;
    \$\@ =~ s/\\v+\$//g;
    \$Nice::Try::EXCEPTION = \$\@;
};

EOT
            $try_sub =~ s/\n/ /gs unless( $self->{debug_code} );
            $try_sub =~ s/__BLOCK_PLACEHOLDER__/$try_block/gs;
            if( $try_def->{open_curly_nl} )
            {
                $try_sub =~ s/__TRY_OPEN_NL__/"\n" x $try_def->{open_curly_nl}/gex;
            }
            else
            {
                $try_sub =~ s/__TRY_OPEN_NL__//gs;
            }
            if( $try_def->{close_curly_nl} )
            {
                $try_sub =~ s/__TRY__CLOSE_NL__/"\n" x $try_def->{close_curly_nl}/gex;
            }
            else
            {
                $try_sub =~ s/__TRY__CLOSE_NL__//gs;
            }
            
            ## Add the final block if there is no catch block, otherwise the final block comes at the end below
            if( !$has_catch_clause )
            {
                $try_sub =~ s/__FINALLY_BLOCK__/$fin_block/gs;
            }
            ## If it should not be here, remove the placeholder
            else
            {
                $try_sub =~ s/__FINALLY_BLOCK__//gs;
            }
            push( @$repl, $try_sub );
        }
        else
        {
            ## $self->_message( 3, "** No try block found!!" );
            next;
        }
        
        my $if_start = <<EOT;
if( \$Nice::Try::DIED ) 
{
    if( \$Nice::Try::HAS_CATCH ) 
    {
EOT
        $if_start =~ s/\n/ /gs unless( $self->{debug_code} );
        push( @$catch_repl, $if_start );
        if( scalar( @$catch_def ) )
        {
            ## $self->_messagef( 3, "Found %d catch blocks", scalar( @$catch_def ) );
            my $total_catch = scalar( @$catch_def );
            ## To count how many times we have else's – obviously we should not have more than 1
            my $else = 0;
            for( my $i = 0; $i < $total_catch; $i++ )
            {
                my $cdef = $catch_def->[$i];
                ## $self->_messagef( 3, "Catch No ${i} new lines before block: %d, after block %d", $cdef->{open_curly_nl}, $cdef->{close_curly_nl} );
                ## Checking for embedded try-catch
                if( my $emb = $self->_parse( $cdef->{block} ) )
                {
                    $cdef->{block} = $emb;
                }
                
                if( $cdef->{var} )
                {
                    ## $self->_messagef( 3, "Catch assignment is: '%s'", $cdef->{var}->content );
                    ## my $str = $cdef->{var}->content;
                    my $str = $self->_serialize( $cdef->{var} );
                    $str =~ s/^\([[:blank:]]*|[[:blank:]]*\)$//g;
                    if( $str =~ /^(\S+)[[:blank:]]+(\$\S+)$/ )
                    {
                        my( $ex_class, $ex_var ) = ( $1, $2 );
                        $cdef->{class} = $ex_class;
                        $cdef->{var} = $ex_var;
                    }
                    else
                    {
                        $cdef->{var} = $str;
                    }
                }
                else
                {
                    ## $self->_message( 3, "No Catch assignment found" );
                }
                if( $cdef->{block} )
                {
                    ## $self->_messagef( 3, "Catch block is:\n%s", $cdef->{block}->content );
                }
                else
                {
                    ## $self->_message( 3, "No catch block found!" );
                    next;
                }
                my $cond;
                if( $i == 0 )
                {
                    $cond = 'if';
                }
                elsif( $i == ( $total_catch - 1 ) )
                {
                    $cond = $total_catch == 1 
                        ? 'if' 
                        : $cdef->{class}
                            ? 'elsif'
                            : 'else';
                }
                else
                {
                    $cond = 'elsif';
                }
                ## $self->_message( 3, "\$i = $i, \$total_catch = $total_catch and cond = '$cond'" );
                ## my $block = $cdef->{block}->content;
                my $block = $self->_serialize( $cdef->{block} );
                $block =~ s/^\{[[:blank:]]*|[[:blank:]]*\}$//gs;
                my $catch_section = '';
                my $catch_code = <<EOT;
            CORE::local \$Nice::Try::CATCH = CORE::sub
            {
                CORE::do __CATCH_OPEN_NL__{ __BLOCK_PLACEHOLDER__ }; __CATCH__CLOSE_NL__
                CORE::return \$Nice::Try::SENTINEL;
            };
            
            if( \$Nice::Try::WANTARRAY ) 
            {
                \@Nice::Try::RETVAL = \&\$Nice::Try::CATCH;
            }
            elsif( defined( \$Nice::Try::WANTARRAY ) )
            {
                \$Nice::Try::RETVAL[0] = \&\$Nice::Try::CATCH;
            } 
            else 
            {
                \&\$Nice::Try::CATCH;
            }
EOT
                if( $cdef->{var} )
                {
                    my $ex_var = $cdef->{var};
                    if( $cdef->{class} )
                    {
                        my $ex_class = $cdef->{class};
                        $catch_section = <<EOT;
        ${cond}( CORE::ref( \$Nice::Try::EXCEPTION ) eq '$ex_class' )
        {
            CORE::local \$\@ = \$Nice::Try::EXCEPTION;
            my $ex_var = \$Nice::Try::EXCEPTION;
$catch_code
        }
EOT
                    }
                    ## No class, just variable assignment like $e or something
                    else
                    {
                        ## $self->_message( 3, "Called here for fallback for element No $i" );
                        if( ++$else > 1 )
                        {
                            ## CORE::warn( "Cannot have more than one falllback catch clause for block: ", $cdef->{block}->content, "\n" ) if( warnings::enabled );
                            CORE::warn( "Cannot have more than one falllback catch clause for block: ", $self->_serialize( $cdef->{block} ), "\n" ) if( warnings::enabled );
                            ## Skip, not die. Not fatal, just ignored
                            next;
                        }
                        $cond = "${cond}( 1 )" if( $cond eq 'if' || $cond eq 'elsif' );
                        # push( @$catch_repl, <<EOT );
                        $catch_section = <<EOT;
        ${cond}
        {
            CORE::local \$\@ = \$Nice::Try::EXCEPTION;
            my $ex_var = \$Nice::Try::EXCEPTION;
$catch_code
        }
EOT
                    }
                }
                ## No variable assignment like $e
                else
                {
                    $cond = "${cond}( 1 )" if( $cond eq 'if' || $cond eq 'elsif' );
                    $catch_section = <<EOT;
        ${cond}
        {
            CORE::local \$\@ = \$Nice::Try::EXCEPTION;
$catch_code
        }
EOT
                }
                $catch_section =~ s/\n/ /gs unless( $self->{debug_code} );
                $catch_section =~ s/__BLOCK_PLACEHOLDER__/$block/gs;
                if( $cdef->{open_curly_nl} )
                {
                    $catch_section =~ s/__CATCH_OPEN_NL__/"\n" x $cdef->{open_curly_nl}/gex;
                }
                else
                {
                    $catch_section =~ s/__CATCH_OPEN_NL__//gs;
                }
                if( $cdef->{close_curly_nl} )
                {
                    $catch_section =~ s/__CATCH__CLOSE_NL__/"\n" x $cdef->{close_curly_nl}/gex;
                }
                else
                {
                    $catch_section =~ s/__CATCH__CLOSE_NL__//gs;
                }
                push( @$catch_repl, $catch_section );
            }
            ## End catch loop
            my $if_end = <<EOT;
    }
EOT
            $if_end =~ s/\n/ /g unless( $self->{debug_code} );
            push( @$catch_repl, $if_end );
        }
        ## No catch clause
        else
        {
            ## If the try-catch block is called inside an eval, propagate the exception
            ## Otherwise, we just make the $@ available
            my $catch_else = <<EOT;
    }
    else
    {
        if( CORE::defined( (CORE::caller(0))[3] ) && (CORE::caller(0))[3] eq '(eval)' )
        {
            CORE::die( \$Nice::Try::EXCEPTION );
        }
        else
        {
            \$\@ = \$Nice::Try::EXCEPTION;
        }
    }
EOT
            $catch_else =~ s/\n/ /g unless( $self->{debug_code} );
            push( @$catch_repl, $catch_else );
        }
        
        ## Add
        my $catch_res = scalar( @$catch_repl ) ? join( '', @$catch_repl ) : '';
        push( @$repl, $catch_res ) if( $catch_res );
        ## Closing the If DIED condition
        push( @$repl, "\};" );

        ## If there is a catch clause, we put the final block here, if any
        if( $has_catch_clause && CORE::length( $fin_block ) )
        {
            push( @$repl, $fin_block );
        }
        
        my $last_return_block = <<EOT;
if( CORE::defined( \$Nice::Try::WANTARRAY ) and 
    (
      !CORE::ref( \$Nice::Try::RETVAL[0] ) or 
      !\$Nice::Try::RETVAL[0]->isa( 'Nice::Try::SENTINEL' ) 
    ) ) 
{
    CORE::return( \$Nice::Try::WANTARRAY ? \@Nice::Try::RETVAL : \$Nice::Try::RETVAL[0] );
}
EOT
        $last_return_block =~ s/\n/ /gs unless( $self->{debug_code} );
        push( @$repl, $last_return_block );
        my $try_catch_code = join( '', @$repl );
        my $token = PPI::Token->new( "; \{ $try_catch_code \}" ) || die( "Unable to create token" );
        $token->set_class( 'Structure' );
        ## $self->_messagef( 3, "Token is '$token' and of class '%s' and inherit from PPI::Token? %s", $token->class, ($token->isa( 'PPI::Token' ) ? 'yes' : 'no' ) );
        my $struct = PPI::Structure->new( $token ) || die( "Unable to create PPI::Structure element" );
        ## $self->_message( 3, "Resulting try-catch block is:\n'$token'" );
        my $orig_try_catch_block = join( '', @$nodes_to_replace );
        ## $self->_message( 3, "Original try-catch block is:\n'$orig_try_catch_block'" );
        ## $self->_messagef( 3, "Element before our try-catch block is of class %s with value '%s'", $element_before_try->class, $element_before_try->content );
        if( !( my $rc = $element_before_try->insert_after( $token ) ) )
        {
            ## $self->_message( 3, "Return code is defined? ", CORE::defined( $rc ) ? 'yes' : 'no', " and is it a PPI::Element object? ", $token->isa( 'PPI::Element' ) ? 'yes' : 'no' );
            $self->_error( "Failed to add replacement code of class '", $token->class, "' after '$element_before_try'" );
            next;
        }
        ## $self->_message( 3, "Return code is defined? ", defined( $rc ) ? "yes" : "no" );
        
        for( my $k = 0; $k < scalar( @$nodes_to_replace ); $k++ )
        {
            my $e = $nodes_to_replace->[$k];
            ## $self->_messagef( 4, "[$k] Removing node: $e" );
            $e->delete || warn( "Could not remove node No $k: '$e'\n" );
        }
    }
    ## End foreach catch found
    
    ## $self->_message( 3, "\n\nResulting code is\n", $elem->content );
    return( $elem );
}

## Taken from PPI::Document
sub _serialize 
{
    my $self   = shift( @_ );
	my $ppi    = shift( @_ ) || return( '' );
	my @tokens = $ppi->tokens;

	# The here-doc content buffer
	my $heredoc = '';

	# Start the main loop
	my $output = '';
	foreach my $i ( 0 .. $#tokens ) {
		my $Token = $tokens[$i];

		# Handle normal tokens
		unless ( $Token->isa('PPI::Token::HereDoc') ) {
			my $content = $Token->content;

			# Handle the trivial cases
			unless ( $heredoc ne '' and $content =~ /\n/ ) {
				$output .= $content;
				next;
			}

			# We have pending here-doc content that needs to be
			# inserted just after the first newline in the content.
			if ( $content eq "\n" ) {
				# Shortcut the most common case for speed
				$output .= $content . $heredoc;
			} else {
				# Slower and more general version
				$content =~ s/\n/\n$heredoc/;
				$output .= $content;
			}

			$heredoc = '';
			next;
		}

		# This token is a HereDoc.
		# First, add the token content as normal, which in this
		# case will definitely not contain a newline.
		$output .= $Token->content;

		# Now add all of the here-doc content to the heredoc buffer.
		foreach my $line ( $Token->heredoc ) {
			$heredoc .= $line;
		}

		if ( $Token->{_damaged} ) {
			# Special Case:
			# There are a couple of warning/bug situations
			# that can occur when a HereDoc content was read in
			# from the end of a file that we silently allow.
			#
			# When writing back out to the file we have to
			# auto-repair these problems if we aren't going back
			# on to the end of the file.

			# When calculating $last_line, ignore the final token if
			# and only if it has a single newline at the end.
			my $last_index = $#tokens;
			if ( $tokens[$last_index]->{content} =~ /^[^\n]*\n$/ ) {
				$last_index--;
			}

			# This is a two part test.
			# First, are we on the last line of the
			# content part of the file
			my $last_line = List::Util::none {
				$tokens[$_] and $tokens[$_]->{content} =~ /\n/
				} (($i + 1) .. $last_index);
			if ( ! defined $last_line ) {
				# Handles the null list case
				$last_line = 1;
			}

			# Secondly, are their any more here-docs after us,
			# (with content or a terminator)
			my $any_after = List::Util::any {
				$tokens[$_]->isa('PPI::Token::HereDoc')
				and (
					scalar(@{$tokens[$_]->{_heredoc}})
					or
					defined $tokens[$_]->{_terminator_line}
					)
				} (($i + 1) .. $#tokens);
			if ( ! defined $any_after ) {
				# Handles the null list case
				$any_after = '';
			}

			# We don't need to repair the last here-doc on the
			# last line. But we do need to repair anything else.
			unless ( $last_line and ! $any_after ) {
				# Add a terminating string if it didn't have one
				unless ( defined $Token->{_terminator_line} ) {
					$Token->{_terminator_line} = $Token->{_terminator};
				}

				# Add a trailing newline to the terminating
				# string if it didn't have one.
				unless ( $Token->{_terminator_line} =~ /\n$/ ) {
					$Token->{_terminator_line} .= "\n";
				}
			}
		}

		# Now add the termination line to the heredoc buffer
		if ( defined $Token->{_terminator_line} ) {
			$heredoc .= $Token->{_terminator_line};
		}
	}

	# End of tokens

	if ( $heredoc ne '' ) {
		# If the file doesn't end in a newline, we need to add one
		# so that the here-doc content starts on the next line.
		unless ( $output =~ /\n$/ ) {
			$output .= "\n";
		}

		# Now we add the remaining here-doc content
		# to the end of the file.
		$output .= $heredoc;
	}

	$output;
}


{
  package # hide from PAUSE
    Nice::Try::ScopeGuard;

    # older versions of perl have an issue with $@ during global destruction
    use constant UNSTABLE_DOLLARAT => ("$]" < '5.013002') ? 1 : 0;

    sub _new 
    {
        my $this = shift( @_ );
        return( bless( [ @_ ] => ( ref( $this ) || $this ) ) );
    }

    sub DESTROY 
    {
        my( $code, @args ) = @{ $_[0] };
        # save the current exception to make it available in the finally sub,
        # and to restore it after the eval
        my $err = $@;
        local $@ if( UNSTABLE_DOLLARAT );
        eval 
        {
            $@ = $err;
            $code->( @args );
            1;
        } 
        or do 
        {
            CORE::warn
            "Execution of finally() block $code resulted in an exception, which "
            . '*CAN NOT BE PROPAGATED* due to fundamental limitations of Perl. '
            . 'Your program will continue as if this event never took place. '
            . "Original exception text follows:\n\n"
            . (defined $@ ? $@ : '$@ left undefined...')
            . "\n"
            ;
        };
        # maybe unnecessary?
        $@ = $err;
    }
}

1;

__END__

=encoding utf-8

=head1 NAME

Nice::Try - A real Try Catch Block Implementation Using Perl Filter

=head1 SYNOPSIS

    use Nice::Try;

    print( "Hello, I want to try\n" );
    # Try out {
    print( "this piece of code\n" );
    try 
    {
        # Not so sure }
        print( "I am trying!\n" );
        die( "Bye cruel world..." );
        # Never going to reach this
        return( 1 );
    }
    # Some comment
    catch( Exception $e ) {
        return( "Caught an exception \$e" );
    }
    # More comment with space too

    catch( $e ) {
        print( "Got an error: $e\n" );
    }
    finally
    {
        print( "Cleaning up\n" );
    }
    print( "Ok, then\n" );

When run, this would produce, as one would expect:

    Hello, I want to try
    this piece of code
    I am trying!
    Got an error: Bye cruel world... at ./some/script.pl line 18.
    Cleaning up
    Ok, then

=head1 VERSION

    v0.1.5

=head1 DESCRIPTION

L<Nice::Try> is a lightweight implementation of Try-Catch exception trapping block using L<perl filter|perlfilter>. It behaves like you would expect. 

Here is a list of its distinctive features:

=over 4

=item * No routine to import like C<Nice::Try qw( try catch )>. Just add C<use Nice::Try> in your script

=item * Properly report the right line number for the original error message

=item * Allows embedded try-catch block within try-catch block, such as:

    use Nice::Try;

    print( "Wow, something went awry: ", &gotcha, "\n" );

    sub gotcha
    {
        print( "Hello, I want to try\n" );
        # Try out {
        CORE::say( 'this piece' );
        try 
        {
            # Not so sure }
            print( "I am trying!\n" );
            try
            {
                die( "Bye cruel world..." );
                return( 1 );
            }
            catch( $err )
            {
                die( "Dying again with embedded error: '$err'" );
            }
        }
        catch( Exception $e ) {
            return( "Caught an exception \$e" );
        }
        catch( $e ) {
            try
            {
                print( "Got an error: $e\n" );
                print( "Trying something else.\n" );
                die( "No really, dying out... with error: $e\n" );
            }
            catch( $err2 )
            {
                return( "Returning from catch L2 with error '$err2'" );
            }
        }
        CORE::say( "Ok, then" );
    }

=item * No need for semicolon on the last closing brace

=item * It does not rely on perl regular expression, but instead uses L<PPI> (short for "Perl Parsing Interface").

=item * Variable assignment in the catch block works. For example:

    try
    {
        # Something or
        die( "Oops\n" );
    }
    catch( $funky_variable_name )
    {
        return( "Oh no: $funky_variable_name" );
    }

=item * C<$@> is always available too

=item * You can return a value from try-catch blocks, even with embedded try-catch blocks

=item * It recognises C<@_> inside try-catch blocks, so you can do something like:

    print( &gotme( 'Jacques' ), "\n" );

    sub gotme
    {
        try
        {
            print( "I am trying my best $_[0]!\n" );
            die( "But I failed\n" );
        }
        catch( $some_reason )
        {
            return( "Failed: $some_reason" );
        }
    }

Would produce:

    I am trying my best Jacques!
    Failed: But I failed

=back

=head1 WHY USE IT?

There are quite a few implementations of try-catch blocks in perl, and they can be grouped in 4 categories:

=over 4

=item 1 Try-Catch as subroutines

For example L<Try::Tiny>

=item 2 Using Perl Filter

For example L<Nice::Try>, L<Try::Harder>

=item 3 Using L<Devel::Declare>

For example L<TryCatch>

=item 4 Others

For example L<Syntax::Keyword::Try>

=back

Group 1 requires the use of semi-colons like:

    try
    {
        # Something
    }
    catch
    {
        # More code
    };

It also imports the subroutines C<try> and C<catch> in your namespace.

And you cannot do exception variable assignment like C<catch( $err )>

In group 2, L<Try::Harder> does a very nice work, but relies on perl regular expression with L<Text::Balanced> and that makes it susceptible to failure if the try-catch block is not written as it expects it to be. For example if you put comments between try and catch, it would not work anymore. This is because parsing perl is famously difficult. Also, it does not do exception variable assignment, or catch filtered based on exception class like:

    try
    {
        # Something
        die( Exception->new( "Failed!" ) );
    }
    catch( Exception $e )
    {
        # Do something if exception is an Exception class
    }

See L<perlfunc/"die"> for more information on dying with an object.

Also L<Try::Harder> will die if you use only C<try> with no catch, such as:

    use Try::Harder;
    try
    {
        die( "Oops\n" );
    }
    # Will never reach this
    print( "Got here with $@\n" );

In this example, the print line will never get executed. With L<Nice::Try> you can use C<try> alone as an equivalent of L<perlfunc/"eval"> and the C<$@> will be available too. So:

    use Nice::Try;
    try
    {
        die( "Oops\n" );
    }
    print( "Got here with $@\n" );

will produces:

    Got here with Oops

In group 3, L<TryCatch> was working wonderfully, but was relying on L<Devel::Declare> which was doing some esoteric stuff and eventually the version 0.006020 broke L<TryCatch> and there seems to be no intention of correcting this breaking change.

In group 4, there is L<Syntax::Keyword::Try>, which is a great alternative if you do not care about exception variable assignment or exception class filter. You can only use C<$@>

So, L<Nice::Try> is quite unique and fill the missing features, but because it is purely in perl and not an XS module, it is slower than XS module like L<Syntax::Keyword::Try>. I am not sure the difference would be noticeable for regular size script, but the parsing with L<PPI> would definitely take more time on larger piece of code like 10,000 lines or more. If you know of a perl parser that uses XS, please let me know.

=head1 FINALLY

Like with other language such as Java or JavaScript, the C<finally> block will be executed even if the C<try> or C<catch> block contains a return statement.

This is useful to do some clean-up. For example:

    try
    {
        # Something worth dying
    }
    catch( $e )
    {
        return( "I failed: $e" );
    }
    finally
    {
        # Do some mop up
        # This would be reached even if catch already returned
        # Putting return statement here does not actually return anything.
        # This is only for clean-up
    }

However, because this is designed for clean-up, it is called in void context, so any C<return> statement there will not actually return anything back to the caller.

=head1 DEBUGGING

And to have L<Nice::Try> save the filtered code to a file, pass it the C<debug_file> parameter like this:

    use Nice::Try debug_file => './updated_script.pl';

You can also call your script using L<Filter::ExtractSource> like this:

    perl -MFilter::ExtractSource script.pl > updated_script.pl

or add C<use Filter::ExtractSource> inside it.

In the updated script produced, you can add the line calling L<Nice::Try> to:

    use Nice::Try no_filter => 1;

to avoid L<Nice::Try> from filtering your script

If you want L<Nice::Try> to produce human readable code, pass it the C<debug_code> parameter like this:

    use Nice::Try debug_code => 1;

=head1 CREDITS

Credits to Stephen R. Scaffidi for his implementation of L<Try::Harder> from which I borrowed some code.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<PPI>, L<Filter::Util::Call>, L<Try::Harder>, L<Syntax::Keyword::Try>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated files under the same terms as Perl itself.

=cut
