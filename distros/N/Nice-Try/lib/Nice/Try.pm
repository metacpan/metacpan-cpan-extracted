##----------------------------------------------------------------------------
## A real Try Catch Block Implementation Using Perl Filter - ~/lib/Nice/Try.pm
## Version v1.3.13
## Copyright(c) 2024 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2020/05/17
## Modified 2024/09/06
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Nice::Try;
BEGIN
{
    require 5.16.0;
    use strict;
    use warnings;
    use warnings::register;
    use vars qw(
        $CATCH $DIED $EXCEPTION $FINALLY $HAS_CATCH @RETVAL $SENTINEL $TRY $WANTARRAY
        $VERSION $ERROR
    );
    use PPI 1.277;
    use Filter::Util::Call;
    use Scalar::Util ();
    use List::Util ();
    use Want ();
    our $VERSION = 'v1.3.13';
    our $ERROR;
    our( $CATCH, $DIED, $EXCEPTION, $FINALLY, $HAS_CATCH, @RETVAL, $SENTINEL, $TRY, $WANTARRAY );
}

use strict;
use warnings;

# Taken from Try::Harder version 0.005
our $SENTINEL = bless( {} => __PACKAGE__ . '::SENTINEL' );

sub import
{
    my( $this, @arguments ) = @_ ;
    my $class = CORE::caller();
    my $hash = { @arguments };
    $hash->{debug} = 0 if( !CORE::exists( $hash->{debug} ) );
    $hash->{no_filter} = 0 if( !CORE::exists( $hash->{no_filter} ) );
    $hash->{debug_code} = 0 if( !CORE::exists( $hash->{debug_code} ) );
    $hash->{debug_dump} = 0 if( !CORE::exists( $hash->{debug_dump} ) );
    $hash->{dont_want} = 0 if( !CORE::exists( $hash->{dont_want} ) );
    # We check if we are running under tie and if so we cannot use Want features, 
    # because they would trigger a segmentation fault.
    $hash->{is_tied} = 0;
    if( $class->can( 'TIESCALAR' ) || $class->can( 'TIEHASH' ) || $class->can( 'TIEARRAY' ) )
    {
        $hash->{is_tied} = 1;
    }
    require overload;
    $hash->{is_overloaded} = overload::Overloaded( $class ) ? 1 : 0;
    $hash->{no_context} = 0;
    # 2021-05-17 (Jacques): the following was a bad idea as it was indiscriminate and 
    # would also affect use of caller outside of try-catch blocks
    # *{"${class}::caller"} = \&{"Nice::Try::caller"};
    filter_add( bless( $hash => ( ref( $this ) || $this ) ) );
}

sub unimport
{       
    filter_del();
}

sub caller($;$)
{
    my $where = shift( @_ );
    my $n = shift( @_ );
    # Offsetting our internal call frames
    my $map = 
    {
    try => 3,
    catch => 3,
    finally => 5,
    };
    my @info = defined( $n ) ? CORE::caller( int( $n ) + $map->{ $where } ) : CORE::caller( 1 + $map->{ $where } );
    return( @info );
}

sub caller_try { return( &Nice::Try::caller( try => @_ ) ); }

sub caller_catch { return( &Nice::Try::caller( catch => @_ ) ); }

sub caller_finally { return( &Nice::Try::caller( finally => @_ ) ); }

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
        $self->_message( 3, "Skiping filtering." ) if( $self->{debug} >= 3 );
        return( $status );
    }
    while( $status = filter_read() )
    {
        # Error
        if( $status < 0 )
        {
            $self->_message( 3, "An error occurred in fiilter, aborting." ) if( $self->{debug} >= 3 );
            return( $status );
        }
        $line++;
        $code .= $_;
        $_ = '';
    }
    return( $line ) if( !$line );
    unless( $status < 0 )
    {
        # 2021-06-05 (Jacques): fixes the issue No. 3 <https://gitlab.com/jackdeguest/Nice-Try/issues/3>
        # Make sure there is at least a space at the beginning
        $code = ' ' . $code;
        if( index( $code, 'try' ) != -1 )
        {
            $self->_message( 4, "Processing $line lines of code." ) if( $self->{debug} >= 4 );
            my $doc = PPI::Document->new( \$code, readonly => 1 ) || die( "Unable to parse: ", PPI::Document->errstr, "\n$code\n" );
            # Remove pod
            # $doc->prune('PPI::Token::Pod');
            $self->_browse( $doc ) if( $self->{debug_dump} );
            if( $doc = $self->_parse( $doc ) )
            {
                $_ = $doc->serialize;
                # $doc->save( "./dev/debug-parsed.pl" );
                # $status = 1;
            }
            # Rollback
            else
            {
                $_ = $code;
    #             $status = -1;
    #             filter_del();
            }
        }
        else
        {
            $self->_message( 4, "There does not seem to be any try block in this code, so skipping." ) if( $self->{debug} >= 4 );
            $_ = $code;
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
            $self->_message( 4, "Reading more line: $_" ) if( $self->{debug} >= 4 );
            return( $status ) if( $status < 0 );
            $line++;
        }
    }
    if( $self->{debug_file} )
    {
        if( open( my $fh, ">$self->{debug_file}" ) )
        {
            binmode( $fh, ':utf8' );
            print( $fh $_ );
            close( $fh );
        }
    }
    return( $line );
}

sub implement
{
    my $self = shift( @_ );
    my $code = shift( @_ );
    return( $code ) if( !CORE::defined( $code ) || !CORE::length( $code ) );
    unless( ref( $self ) )
    {
        my $opts = ( !@_ || !defined( $_[0] ) )
            ? {}
            : ref( $_[0] ) eq 'HASH'
                ? shift( @_ )
                : !( @_ % 2 )
                    ? { @_ }
                    : {};
        for( qw( debug no_context no_filter debug_code debug_dump debug_file dont_want is_tied is_overloaded ) )
        {
            $opts->{ $_ } //= 0;
        }
        $self = bless( $opts => $self );
    }
    # 2021-06-05 (Jacques): fixes the issue No. 3 <https://gitlab.com/jackdeguest/Nice-Try/issues/3>
    # Make sure there is at least a space at the beginning
    $code = ' ' . $code;
    $self->_message( 4, "Processing ", CORE::length( $code ), " bytes of code." ) if( $self->{debug} >= 4 );
    my $doc = PPI::Document->new( \$code, readonly => 1 ) || die( "Unable to parse: ", PPI::Document->errstr, "\n$code\n" );
    $self->_browse( $doc ) if( $self->{debug_dump} );
    if( $doc = $self->_parse( $doc ) )
    {
        $code = $doc->serialize;
    }
    return( $code );
}

sub _browse
{
    my $self = shift( @_ );
    my $elem = shift( @_ );
    my $level = shift( @_ ) || 0;
    if( $self->{debug} >= 4 )
    {
        $self->_message( 4, "Checking code: ", $self->_serialize( $elem ) ) if( $self->{debug} >= 4 );
        $self->_messagef( 4, "PPI element of class %s has children property '%s'.", $elem->class, $elem->{children} ) if( $self->{debug} >= 4 );
    }
    return if( !$elem->children );
    foreach my $e ( $elem->elements )
    {
        printf( STDERR "%sElement: [%d] class %s, value %s\n", ( '.' x $level ), ( $e->line_number // 'undef' ), ( $e->class // 'undef' ), ( $e->content // 'undef' ) );
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
        $txt =~ s/[\015\012]+$//g;
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
    my $stackFrame = 0;
    my( $pkg, $file, $line, @otherInfo ) = CORE::caller( $stackFrame );
    my $sub = ( CORE::caller( $stackFrame + 1 ) )[3];
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
    my $stackFrame = 0;
    my $fmt = shift( @data );
    my( $pkg, $file, $line, @otherInfo ) = CORE::caller( $stackFrame );
    my $sub = ( CORE::caller( $stackFrame + 1 ) )[3];
    my $sub2 = substr( $sub, rindex( $sub, '::' ) + 2 );
    for( @data )
    {
        next if( ref( $_ ) );
        s/\b\%/\x{025}/g;
    }
    my $txt = "${pkg}::${sub2}( $self ) [$line]: " . sprintf( $fmt, map( ref( $_ ) eq 'CODE' ? $_->() : $_, @data ) );
    $txt    =~ s/\n$//gs;
    $txt = '## ' . join( "\n## ", split( /\n/, $txt ) );
    CORE::print( STDERR $txt, "\n" );
}

sub _parse
{
    my $self = shift( @_ );
    my $elem = shift( @_ );
    no warnings 'uninitialized';
    if( !Scalar::Util::blessed( $elem ) || !$elem->isa( 'PPI::Node' ) )
    {
        return( $self->_error( "Element provided to parse is not a PPI::Node object" ) );
    }

    my $check_consecutive_blocks;
    $check_consecutive_blocks = sub
    {
        my $top_elem = shift( @_ );
        my $level = shift( @_ );
        my $ref = $top_elem->find(sub
        {
            my( $top, $this ) = @_;
            return( $this->class eq 'PPI::Statement' && substr( $this->content, 0, 3 ) eq 'try' ? 1 : 0 );
        });
        return( $self->_error( "Failed to find any try-catch clause: $@" ) ) if( !defined( $ref ) );
        $self->_messagef( 4, "[blocks check level ${level}] Found %d match(es) for try statement", scalar( @$ref ) ) if( $ref && ref( $ref ) && $self->{debug} >= 4 );
        return if( !$ref || !scalar( @$ref ) );
        # We will store the additional blocks here, and we will dig deeper into them recursively.
        my $has_additional_blocks = 0;
    
        # NOTE: Checking for consecutive try-catch block statements
        # 2020-09-13: PPI will return 2 or more consecutive try-catch block as 1 statement
        # It does not tell them apart, so we need to post process the result to effectively search within for possible for other try-catch blocks and update the @$ref array consequently
        # Array to contain the new version of the $ref array.
        my $alt_ref = [];
        $self->_message( 3, "[blocks check level ${level}] Checking for consecutive try-catch blocks in ", scalar( @$ref ), " results found by PPI" ) if( $self->{debug} >= 3 );
        foreach my $this ( @$ref )
        {
            $self->_message( 3, "[blocks check level ${level}] Getting children from object '", overload::StrVal( $this ), "'" ) if( $self->{debug} >= 3 );
            $self->_message( 3, "[blocks check level ${level}] Checking if following code has children" ) if( $self->{debug} >= 3 );
            # my( @block_children ) = ( exists( $this->{children} ) && ref( $this->{children} // '' ) eq 'ARRAY' ) ? $this->children : ();
            # Stringifying forces PPI to set the object children somehow
            my $ct = "$this";
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
                # We found a try-catch block. Move the buffer to $alt_ref
                if( $sib->class eq 'PPI::Token::Word' && $sib->content eq 'try' )
                {
                    # Look ahead for a block...
                    my $next = $sib->snext_sibling;
                    if( $next && $next->class eq 'PPI::Structure::Block' )
                    {
                        $has_additional_blocks++;
                        $self->_messagef( 3, "[blocks check level ${level}] Found consecutive try-block at line %d.", $sib->line_number ) if( $self->{debug} >= 3 );
                        # Push the previous statement $st to the stack $alt_ref
                        $self->_messagef( 3, "[blocks check level ${level}] Saving previous %d nodes collected.", scalar( @$tmp_nodes ) ) if( $self->{debug} >= 3 );
                        push( @$tmp_ref, $tmp_nodes );
                        $tmp_nodes = [];
                    }
                }
                push( @$tmp_nodes, $sib );
                $prev_sib = $sib;
            }
            $self->_messagef( 3, "[blocks check level ${level}] Saving last %d nodes collected.", scalar( @$tmp_nodes ) ) if( $self->{debug} >= 3 );
            push( @$tmp_ref, $tmp_nodes );
            $self->_messagef( 3, "[blocks check level ${level}] Found %d try-catch block(s) in initial PPI result.", scalar( @$tmp_ref ) ) if( $self->{debug} >= 3 );
            # If we did find consecutive try-catch blocks, we add each of them after the nominal one and remove the nominal one after. The nominal one should be empty by then
            if( scalar( @$tmp_ref ) > 1 )
            {
                my $last_obj = $this;
                my $spaces = [];
                foreach my $arr ( @$tmp_ref )
                {
                    $self->_message( 3, "[blocks check level ${level}] Adding statement block with ", scalar( @$arr ), " children after one at line ", $last_obj->line_number, ": '", substr( $last_obj, 0, 255 ), "'" ) if( $self->{debug} >= 3 );
                    # 2021-06-05 (Jacques): Fixing issue No. 2: <https://gitlab.com/jackdeguest/Nice-Try/issues/2>
                    # Find the last block that belongs to us
                    $self->_message( 4, "[blocks check level ${level}] Checking first level objects collected." ) if( $self->{debug} >= 4 );
                    my $last_control = '';
                    my $last_block;
                    my $last = {};
                    foreach my $o ( @$arr )
                    {
                        if( $o->class eq 'PPI::Structure::Block' && $last_control )
                        {
                            $last->{block} = $o;
                            $last->{control} = $last_control;
                            $last_control = '';
                        }
                        elsif( $o->class eq 'PPI::Token::Word' )
                        {
                            my $ct = $o->content;
                            if( $ct eq 'try' || $ct eq 'catch' || $ct eq 'finally' )
                            {
                                $last_control = $o;
                            }
                        }
                    }
                    
                    # Get the trailing insignificant elements at the end of the statement and move them out of the statement
                    my $insignificants = [];
                    while( scalar( @$arr ) > 0 )
                    {
                        my $o = $arr->[-1];
                        # 2021-06-05 (Jacques): We don't just look for the last block, because
                        # that was making a bad assumption that the last trailing block would be our
                        # try-catch block.
                        # Following issue No. 2 reported with a trailing anonymous subroutine,
                        # We remove everything up until our known last block that belongs to us.
                        last if( $o->class eq 'PPI::Structure::Block' && Scalar::Util::refaddr( $o ) eq Scalar::Util::refaddr( $last->{block} ) );
                        unshift( @$insignificants, pop( @$arr )->remove );
                    }
                    $self->_messagef( 3, "[blocks check level ${level}] %d insignificant objects found.", scalar( @$insignificants ) ) if( $self->{debug} >= 3 );
                    
                    my $new_code = join( '', map( "$_", @$arr ) );
                    $self->_message( 3, "[blocks check level ${level}] Parsing new code to extract statement:\n${new_code}" ) if( $self->{debug} >= 3 );
                    # 2021-06-05 (Jacques): It is unfortunately difficult to simply add a new PPI::Statement object
                    # Instead, we have PPI parse our new code and we grab what we need.
                    my $new_block = PPI::Document->new( \$new_code, readonly => 1 );
                    # my $st = $new_block->{children}->[0]->remove;
                    my $st;
                    for( my $i = 0; $i < scalar( @{$new_block->{children}} ); $i++ )
                    {
                        if( Scalar::Util::blessed( $new_block->{children}->[$i] ) &&
                            $new_block->{children}->[$i]->isa( 'PPI::Statement' ) )
                        {
                            $st = $new_block->{children}->[$i]->remove;
                            last;
                        }
                    }
                    
                    foreach my $o ( @$arr )
                    {
                        # We remove the object from its parent, now that it has become useless
                        my $old = $o->remove || die( "Unable to remove element '$o'\n" );
                    }
                    my $err = '';
                    $self->_messagef( 3, "[blocks check level ${level}] Adding the statement object after last object '%s' of class '%s' with parent with class '%s'.", Scalar::Util::refaddr( $last_obj ), ( defined( $last_obj ) ? $last_obj->class : 'undefined class' ), ( defined( $last_obj ) ? $last_obj->parent->class : 'undefined parent class' ) ) if( $self->{debug} >= 3 );
                    # my $rc = $last_obj->insert_after( $st );
                    my $rc;
                    if( $last_obj->class eq 'PPI::Token::Whitespace' )
                    {
                        $rc = $last_obj->__insert_after( $st );
                    }
                    elsif( $last_obj->class eq 'PPI::Token::Comment' )
                    {
                        # $rc = $last_obj->parent->__insert_after_child( $last_obj, $st );
                        $rc = $last_obj->__insert_after( $st );
                    }
                    else
                    {
                        $rc = $last_obj->insert_after( $st );
                    }
                    
                    if( !defined( $rc ) )
                    {
                        $err = sprintf( 'Object to be added after last try-block statement must be a PPI::Element. Class provided is \"%s\".', $st->class );
                    }
                    elsif( !$rc )
                    {
                        my $requires;
                        if( $last_obj->isa( 'PPI::Structure' ) ||
                            $last_obj->isa( 'PPI::Token' ) )
                        {
                            $requires = 'PPI::Structure or PPI::Token';
                        }
                        elsif( $last_obj->isa( 'PPI::Statement' ) )
                        {
                            $requires = 'PPI::Statement or PPI::Token';
                        }
                        $err = sprintf( "Object of class \"%s\" could not be added after object with address '%s' and of class '%s' with parent '%s' with class '%s': '$last_obj'. The object of class '%s' must be a ${requires} object.", $st->class, Scalar::Util::refaddr( $last_obj ), $last_obj->class, Scalar::Util::refaddr( $last_obj->parent ), $last_obj->parent->class, $st->class );
                    }
                    else
                    {
                        $last_obj = $st;
                        if( scalar( @$insignificants ) )
                        {
                            $self->_messagef( 4, "[blocks check level ${level}] Adding %d trailing insignificant objects after last element of class '%s'", scalar( @$insignificants ), $last_obj->class ) if( $self->{debug} >= 4 );
                            foreach my $o ( @$insignificants )
                            {
                                $self->_messagef( 4, "[blocks check level ${level}] Adding trailing insignificant object of class '%s' after last element of class '%s'", $o->class, $last_obj->class ) if( $self->{debug} >= 4 );
                                # printf( STDERR "Inserting object '%s' (%s) of type '%s' after object '%s' (%s) of type %s who has parent '%s' of type '%s'\n", overload::StrVal( $o ), Scalar::Util::refaddr( $o ), ref( $o ), overload::StrVal( $last_obj), Scalar::Util::refaddr( $last_obj ), ref( $last_obj ), overload::StrVal( $last_obj->parent ), ref( $last_obj->parent ) );
                                CORE::eval
                                {
                                    $rc = $last_obj->insert_after( $o ) ||
                                    do
                                    {
                                        warn( "Failed to insert object of class '", $o->class, "' before last object of class '", $st->class, "'\n" ) if( $self->{debug} );
                                    };
                                };
                                if( $@ )
                                {
                                    if( ref( $o ) )
                                    {
                                        warn( "Failed to insert object of class '", $o->class, "' before last object of class '", $st->class, "': $@\n" ) if( $self->{debug} );
                                    }
                                    else
                                    {
                                        warn( "Was expecting an object to insert before last object of class '", $st->class, "', but instead got '$o': $@\n" ) if( $self->{debug} );
                                    }
                                }
                                elsif( !defined( $rc ) )
                                {
                                    warn( sprintf( 'Object to be added after last try-block statement must be a PPI::Element. Class provided is \"%s\".', $o->class ) ) if( $self->{debug} );
                                }
                                elsif( !$rc )
                                {
                                    warn( sprintf( "Object of class \"%s\" could not be added after object of class '%s': '$last_obj'.", $o->class, $last_obj->class ) ) if( $self->{debug} );
                                }
                                # printf( STDERR "Object inserted '%s' (%s) of class '%s' now has parent '%s' (%s) of class '%s'\n", overload::StrVal( $o ), Scalar::Util::refaddr( $o ), ref( $o ), overload::StrVal( $o->parent ), Scalar::Util::refaddr( $o->parent ), ref( $o->parent ) );
                                $o->parent( $last_obj->parent ) if( !$o->parent );
                                $last_obj = $o;
                            }
                        }
                    }
                    die( $err ) if( length( $err ) );
                    push( @$alt_ref, $st );
                }
                my $parent = $this->parent;
                # Completely destroy it; it is now replaced by our updated code
                $this->delete;
            }
            else
            {
                push( @$alt_ref, $this );
            }
        }
        $self->_messagef( 3, "[blocks check level ${level}] Results found increased from %d to %d results.", scalar( @$ref ), scalar( @$alt_ref ) ) if( $self->{debug} >= 3 );

        if( $has_additional_blocks )
        {
            $self->_message( 3, "[blocks check level ${level}] Consecutive block search now found ", scalar( @$alt_ref ), " try blocks." ) if( $self->{debug} >= 3 );
            my $more = [];
            foreach my $el ( @$alt_ref )
            {
                push( @$more, $el );
                my $rv = $check_consecutive_blocks->( $el, ( $level + 1 ) );
                if( ref( $rv ) && scalar( @$rv ) )
                {
                    push( @$more, @$rv );
                }
            }
            return( $more );
        }
        else
        {
            return( $ref );
        }
    };
    my $ref = $check_consecutive_blocks->( $elem => 0 );
    return if( !$ref || !scalar( @$ref ) );
    
    $self->_messagef( 3, "Implementing try-catch for %d try-catch blocks.", scalar( @$ref ) ) if( $self->{debug} >= 3 );
    # NOTE: processing implementation of our try-catch
    foreach my $this ( @$ref )
    {
        $self->_browse( $this ) if( $self->{debug} >= 5 );
        my $element_before_try = $this->previous_sibling;
        my $try_block_ref = [];
        # Contains the finally block reference
        my $fin_block_ref = [];
        my $nodes_to_replace = [];
        my $catch_def = [];
        # Replacement data
        my $repl = [];
        my $catch_repl = [];
        
        # There is a weird bug in PPI that I have searched but could not find
        # If I don't attempt to stringify, I may end up with a PPI::Statement object that has no children as an array reference
        my $ct = "$this";
        my( @block_children ) = $this->children;
        next if( !scalar( @block_children ) );
        my $prev_sib = $block_children[0];
        push( @$nodes_to_replace, $prev_sib );
        my( $inside_catch, $inside_finally );
        my $temp = {};
        # Buffer of nodes found in between blocks
        my $buff = [];
        # Temporary new line counter between try-catch block so we can reproduce it and ensure proper reporting of error line
        my $nl_counter = 0;
        my $sib;
        while( $sib = $prev_sib->next_sibling )
        {
            if( !scalar( @$try_block_ref ) )
            {
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
                elsif( $sib->class eq 'PPI::Token::Whitespace' && $sib->content =~ /[\015\012]+/ )
                {
                    $temp->{open_curly_nl}++;
                    push( @$buff, $sib );
                }
                # We skip anything else until we find that try block
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
                # This is the catch list as in catch( $e ) or catch( Exception $e )
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
                elsif( $sib->class eq 'PPI::Token::Whitespace' && $sib->content =~ /[\015\012]+/ )
                {
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
                # We could ignore it, but it is best to let the developer know in case he/she counts on it somehow
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
                elsif( $sib->class eq 'PPI::Token::Whitespace' && $sib->content =~ /[\015\012]+/ )
                {
                    $temp->{open_curly_nl}++;
                    push( @$nodes_to_replace, $sib );
                }
                else
                {
                    push( @$nodes_to_replace, $sib );
                }
            }
            # Check for new lines after closing blocks. The ones before, we can account for them in each section above
            # We could have } catch {
            # or
            # }
            # catch {
            # etc.
            # This could also be new lines following the last catch block
            elsif( $sib->class eq 'PPI::Token::Whitespace' && $sib->content =~ /[\015\012]+/ )
            {
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
        
        # NOTE: processing finally block
        # Prepare the finally block, if any, and add it below at the appropriate place
        my $fin_block = '';
        if( scalar( @$fin_block_ref ) )
        {
            my $fin_def = $fin_block_ref->[0];
            $self->_process_sub_token( $fin_def->{block} );
            $self->_process_caller( finally => $fin_def->{block} );
            ## my $finally_block = $fin_def->{block}->content;
            my $finally_block = $self->_serialize( $fin_def->{block} );
            $finally_block =~ s/^\{[[:blank:]]*|[[:blank:]]*\}$//gs;
            $fin_block = <<EOT;
CORE::local \$Nice::Try::FINALLY = Nice\::Try\::ScopeGuard->_new(sub __FINALLY_OPEN_NL__{ __BLOCK_PLACEHOLDER__ __FINALLY__CLOSE_NL__}, [\@_], \$Nice::Try::CATCH_DIED);
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

        # NOTE: processing try blocks
        # Found any try block at all?
        if( scalar( @$try_block_ref ) )
        {
            my $try_def = $try_block_ref->[0];
            
            # Checking for embedded try-catch
            if( my $emb = $self->_parse( $try_def->{block} ) )
            {
                $try_def->{block} = $emb;
            }
            
            $self->_process_loop_breaks( $try_def->{block} );
            # NOTE: process, in try block, __SUB__ which reference current sub since perl v5.16
            $self->_process_sub_token( $try_def->{block} );
            $self->_process_caller( try => $try_def->{block} );
            
            # my $try_block = $try_def->{block}->content;
            my $try_block = $self->_serialize( $try_def->{block} );
            $try_block =~ s/^\{[[:blank:]]*|[[:blank:]]*\}$//gs;
            
            my $try_sub = <<EOT;
CORE::local \$Nice::Try::THREADED;
if( \$INC{'threads.pm'} && !CORE::exists( \$INC{'forks.pm'} ) )
{
    \$Nice::Try::THREADED = threads->tid;
}
CORE::local \$Nice::Try::WANT;
CORE::local ( \$Nice::Try::EXCEPTION, \$Nice::Try::DIED, \$Nice::Try::CATCH_DIED, \@Nice::Try::RETVAL, \@Nice::Try::VOID, \$Nice::Try::RETURN );
CORE::local \$Nice::Try::WANTARRAY = CORE::wantarray;
CORE::local \$Nice::Try::RETURN = sub
{
    \$Nice::Try::NEED_TO_RETURN++;
    return( wantarray() ? \@_ : \$_[0] );
};
EOT
            if( !$self->{is_tied} && !$self->{dont_want} && !$self->{is_overloaded} )
            {
                $try_sub .= <<EOT;
CORE::local \$Nice::Try::NOOP = sub
{
    my \$ref = CORE::shift( \@_ );
    CORE::return(sub{ CORE::return( \$ref ) });
};
if( CORE::defined( \$Nice::Try::WANTARRAY ) && !\$Nice::Try::THREADED && !( !CORE::length( [CORE::caller]->[1] ) && [CORE::caller(1)]->[3] eq '(eval)' ) )
{
    CORE::eval "\\\$Nice::Try::WANT = Want::want( 'LIST' )
            ? 'LIST'
            : Want::want( 'HASH' )
                ? 'HASH'
                : Want::want( 'ARRAY' )
                    ? 'ARRAY'
                    : Want::want( 'OBJECT' )
                        ? 'OBJECT'
                        : Want::want( 'CODE' )
                            ? 'CODE'
                            : Want::want( 'REFSCALAR' )
                                ? 'REFSCALAR'
                                : Want::want( 'BOOL' )
                                    ? 'BOOLEAN'
                                    : Want::want( 'GLOB' )
                                        ? 'GLOB'
                                        : Want::want( 'SCALAR' )
                                            ? 'SCALAR'
                                            : Want::want( 'VOID' )
                                                ? 'VOID'
                                                : '';";
    undef( \$Nice::Try::WANT ) if( \$\@ );
}
EOT
            }
            $try_sub .= <<EOT;
CORE::local \$Nice::Try::TRY = CORE::sub
{
    \@Nice::Try::LAST_VAL = CORE::do __TRY_OPEN_NL__{ __BLOCK_PLACEHOLDER__ };__TRY__CLOSE_NL__
    CORE::return( \@Nice::Try::LAST_VAL ) if( !CORE::defined( \$Nice::Try::WANTARRAY ) && CORE::scalar( \@Nice::Try::LAST_VAL ) );
    \$Nice::Try::VOID[0] = \$Nice::Try::SENTINEL;
    if( CORE::defined( \$Nice::Try::WANT ) && CORE::length( \$Nice::Try::WANT ) )
    {
        if( \$Nice::Try::WANT eq 'OBJECT' )
        {
            CORE::return( Nice::Try::ObjectContext->new( sub{ \$Nice::Try::VOID[0] } )->callback() );
        }
        elsif( \$Nice::Try::WANT eq 'CODE' )
        {
            CORE::return( sub{ \$Nice::Try::VOID[0] } );
        }
        elsif( \$Nice::Try::WANT eq 'HASH' )
        {
            CORE::return( { dummy => \$Nice::Try::VOID[0] } );
        }
        elsif( \$Nice::Try::WANT eq 'ARRAY' )
        {
            CORE::return( [ \$Nice::Try::VOID[0] ] );
        }
        elsif( \$Nice::Try::WANT eq 'REFSCALAR' )
        {
            CORE::return( \\\$Nice::Try::VOID[0] );
        }
        elsif( \$Nice::Try::WANT eq 'GLOB' )
        {
            CORE::return( \*{ \$Nice::Try::VOID[0] } );
        }
        elsif( \$Nice::Try::WANT eq 'LIST' )
        {
            CORE::return( \$Nice::Try::VOID[0] );
        }
        elsif( \$Nice::Try::WANT eq 'BOOLEAN' )
        {
            CORE::return( \$Nice::Try::VOID[0] );
        }
        elsif( \$Nice::Try::WANT eq 'VOID' )
        {
            CORE::return( \$Nice::Try::VOID[0] );
        }
        elsif( \$Nice::Try::WANT eq 'SCALAR' )
        {
            CORE::return( \$Nice::Try::VOID[0] );
        }
    }
    else
    {
        if( \$Nice::Try::WANTARRAY ) 
        {
            CORE::return( \$Nice::Try::VOID[0] );
        }
        elsif( defined( \$Nice::Try::WANTARRAY ) ) 
        {
            CORE::return( \$Nice::Try::VOID[0] );
        }
        else 
        {
            CORE::return( \$Nice::Try::VOID[0] );
        }
    }
};
__FINALLY_BLOCK__ CORE::local \$Nice::Try::HAS_CATCH = $has_catch_clause;
EOT
            $try_sub .= <<EOT;
{
    CORE::local \$\@;
    CORE::eval 
    {
EOT
            if( $] >= 5.036000 )
            {
                $try_sub .= <<EOT;
        no warnings 'experimental::args_array_with_signatures';
EOT
            }

            $try_sub .= <<EOT;
        if( CORE::defined( \$Nice::Try::WANT ) && CORE::length( \$Nice::Try::WANT ) )
        {
            if( \$Nice::Try::WANT eq 'OBJECT' )
            {
                \$Nice::Try::RETVAL[0] = Nice::Try::ObjectContext->new( &\$Nice::Try::TRY )->callback();
            }
            elsif( \$Nice::Try::WANT eq 'CODE' )
            {
                \$Nice::Try::RETVAL[0] = \$Nice::Try::NOOP->( &\$Nice::Try::TRY )->();
            }
            elsif( \$Nice::Try::WANT eq 'HASH' )
            {
                \@Nice::Try::RETVAL = \%{ &\$Nice::Try::TRY };
            }
            elsif( \$Nice::Try::WANT eq 'ARRAY' )
            {
                \@Nice::Try::RETVAL = \@{ &\$Nice::Try::TRY };
            }
            elsif( \$Nice::Try::WANT eq 'REFSCALAR' )
            {
                \$Nice::Try::RETVAL[0] = \${&\$Nice::Try::TRY};
            }
            elsif( \$Nice::Try::WANT eq 'GLOB' )
            {
                \$Nice::Try::RETVAL[0] = \*{ &\$Nice::Try::TRY };
            }
            elsif( \$Nice::Try::WANT eq 'LIST' )
            {
                \@Nice::Try::RETVAL = &\$Nice::Try::TRY;
            }
            elsif( \$Nice::Try::WANT eq 'BOOLEAN' )
            {
                \$Nice::Try::RETVAL[0] = &\$Nice::Try::TRY ? 1 : 0;
                \$Nice::Try::RETVAL[0] = \$Nice::Try::VOID[0] if( scalar( \@Nice::Try::VOID ) );
            }
            elsif( \$Nice::Try::WANT eq 'VOID' )
            {
                \@Nice::Try::VOID = &\$Nice::Try::TRY;
            }
            elsif( \$Nice::Try::WANT eq 'SCALAR' )
            {
                \$Nice::Try::RETVAL[0] = &\$Nice::Try::TRY;
            }
        }
        else
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
                \$Nice::Try::RETVAL[0] = \$Nice::Try::LAST_VAL if( CORE::defined( \$Nice::Try::LAST_VAL ) );
            }
        }
    };
    \$Nice::Try::DIED = CORE::length( \$\@ ) ? 1 : 0;
    \$\@ =~ s/[\\015\\012]+\$//g unless( Scalar::Util::blessed( \$\@ ) );
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
            
            # Add the final block if there is no catch block, otherwise the final block comes at the end below
            if( !$has_catch_clause )
            {
                $try_sub =~ s/__FINALLY_BLOCK__/$fin_block/gs;
            }
            # If it should not be here, remove the placeholder
            else
            {
                $try_sub =~ s/__FINALLY_BLOCK__//gs;
            }
            push( @$repl, $try_sub );
        }
        else
        {
            next;
        }
        
        # NOTE: processing catch block
        my $if_start = <<EOT;
if( \$Nice::Try::DIED ) 
{
    if( \$Nice::Try::HAS_CATCH ) 
    {
EOT
        if( $] >= 5.036000 )
        {
            $if_start .= <<EOT;
        no warnings 'experimental::args_array_with_signatures';
EOT
        }
        $if_start =~ s/\n/ /gs unless( $self->{debug_code} );
        push( @$catch_repl, $if_start );
        if( scalar( @$catch_def ) )
        {
            my $total_catch = scalar( @$catch_def );
            # To count how many times we have else's – obviously we should not have more than 1
            my $else = 0;
            for( my $i = 0; $i < $total_catch; $i++ )
            {
                my $cdef = $catch_def->[$i];
                # Checking for embedded try-catch
                if( my $emb = $self->_parse( $cdef->{block} ) )
                {
                    $cdef->{block} = $emb;
                }
                # NOTE: process, in catch block, __SUB__ which reference current sub since perl v5.16
                $self->_process_sub_token( $cdef->{block} );
                
                if( $cdef->{var} )
                {
                    $cdef->{var}->prune( 'PPI::Token::Comment' );
                    $cdef->{var}->prune( 'PPI::Token::Pod' );
                    $self->_messagef( 3, "Catch assignment is: '%s'", $cdef->{var}->content ) if( $self->{debug} >= 3 );
                    # my $str = $cdef->{var}->content;
                    my $str = $self->_serialize( $cdef->{var} );
                    $str =~ s/^\([[:blank:]\h\v]*|[[:blank:]]*\)$//g;
                    # My::Exception $e
                    if( $str =~ /^(\S+)[[:blank:]\h\v]+(\$\S+)$/ )
                    {
                        @$cdef{qw( class var )} = ( $1, $2 );
                    }
                    elsif( $str =~ /^(\S+)[[:blank:]\h\v]+(\$\S+)[[:blank:]\h\v]+where[[:blank:]\h\v]+\{(.*?)\}$/ )
                    {
                        @$cdef{qw( class var where )} = ( $1, $2, $3 );
                    }
                    elsif( $str =~ /^(\$\S+)[[:blank:]\h\v]+where[[:blank:]\h\v]+\{(.*?)\}$/ )
                    {
                        @$cdef{qw( var where )} = ( $1, $2 );
                    }
                    elsif( $str =~ /^(\$\S+)[[:blank:]\h\v]+isa[[:blank:]\h\v]+(\S+)(?:[[:blank:]\h\v]+where[[:blank:]\h\v]+\{(.*?)\})?$/ )
                    {
                        @$cdef{qw( var class where )} = ( $1, $2, $3 );
                    }
                    elsif( $str =~ /^(?<var>\$\S+)[[:blank:]\h\v]+isa[[:blank:]\h\v]*\([[:blank:]\h\v]*(?<quote>["'])?(?<class>[^[:blank:]\h\v\'\"\)]+)\k{quote}[[:blank:]\h\v]*\)(?:[[:blank:]\h\v]+where[[:blank:]\h\v]+\{(?<where>.*?)\})?$/ )
                    {
                        @$cdef{qw( var class where )} = ( $+{var}, $+{class}, $+{where} );
                    }
                    else
                    {
                        $cdef->{var} = $str;
                    }
                }
                else
                {
                    # $self->_message( 3, "No Catch assignment found" ) if( $self->{debug} >= 3 );
                }
                
                if( $cdef->{block} )
                {
                    # $self->_messagef( 3, "Catch block is:\n%s", $cdef->{block}->content ) if( $self->{debug} >= 3 );
                }
                else
                {
                    # $self->_message( 3, "No catch block found!" ) if( $self->{debug} >= 3 );
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
                # my $block = $cdef->{block}->content;
                $self->_process_loop_breaks( $cdef->{block} );
                $self->_process_sub_token( $cdef->{block} );
                $self->_process_caller( catch => $cdef->{block} );
                my $block = $self->_serialize( $cdef->{block} );
                $block =~ s/^\{[[:blank:]]*|[[:blank:]]*\}$//gs;
                my $catch_section = '';
                my $catch_code = <<EOT;
            CORE::local \$Nice::Try::CATCH = CORE::sub
            {
                \@Nice::Try::LAST_VAL = CORE::do __CATCH_OPEN_NL__{ __BLOCK_PLACEHOLDER__ }; __CATCH__CLOSE_NL__
                CORE::return( \@Nice::Try::LAST_VAL ) if( !CORE::defined( \$Nice::Try::WANTARRAY ) && CORE::scalar( \@Nice::Try::LAST_VAL ) );
                CORE::return \$Nice::Try::SENTINEL;
            };
            
            eval
            {
                local \$\@ = \$Nice::Try::EXCEPTION;
                if( CORE::defined( \$Nice::Try::WANT ) && CORE::length( \$Nice::Try::WANT ) )
                {
                    if( \$Nice::Try::WANT eq 'OBJECT' )
                    {
                        \$Nice::Try::RETVAL[0] = Nice::Try::ObjectContext->new( \&\$Nice::Try::CATCH )->callback();
                    }
                    elsif( \$Nice::Try::WANT eq 'CODE' )
                    {
                        \$Nice::Try::RETVAL[0] = \$Nice::Try::NOOP->( \&\$Nice::Try::CATCH )->();
                    }
                    elsif( \$Nice::Try::WANT eq 'HASH' )
                    {
                        \@Nice::Try::RETVAL = \%{ \&\$Nice::Try::CATCH };
                    }
                    elsif( \$Nice::Try::WANT eq 'ARRAY' )
                    {
                        \@Nice::Try::RETVAL = \@{ \&\$Nice::Try::CATCH };
                    }
                    elsif( \$Nice::Try::WANT eq 'REFSCALAR' )
                    {
                        \$Nice::Try::RETVAL[0] = \${\&\$Nice::Try::CATCH};
                    }
                    elsif( \$Nice::Try::WANT eq 'GLOB' )
                    {
                        \$Nice::Try::RETVAL[0] = \*{ \&\$Nice::Try::CATCH };
                    }
                    elsif( \$Nice::Try::WANT eq 'LIST' )
                    {
                        \@Nice::Try::RETVAL = \&\$Nice::Try::CATCH;
                    }
                    elsif( \$Nice::Try::WANT eq 'BOOLEAN' )
                    {
                        my \$this = \&\$Nice::Try::CATCH ? 1 : 0;
                        \$Nice::Try::RETVAL[0] = \$Nice::Try::VOID[0] if( scalar( \@Nice::Try::VOID ) );
                    }
                    elsif( \$Nice::Try::WANT eq 'VOID' )
                    {
                        \@Nice::Try::VOID = \&\$Nice::Try::CATCH;
                    }
                    elsif( \$Nice::Try::WANT eq 'SCALAR' )
                    {
                        \$Nice::Try::RETVAL[0] = \&\$Nice::Try::CATCH;
                    }
                }
                else
                {
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
                }
            };
            \$Nice::Try::CATCH_DIED = \$\@ if( \$\@ );
EOT
                if( $cdef->{var} )
                {
                    my $ex_var = $cdef->{var};
                    if( $cdef->{class} && $cdef->{where} )
                    {
                        my $ex_class = $cdef->{class};
                        my $eval = "q{CORE::local \$_ = \$Nice::Try::EXCEPTION; my $ex_var = \$Nice::Try::EXCEPTION; CORE::local \$\@ = \$Nice::Try::EXCEPTION; $cdef->{where}}";
                        $catch_section = <<EOT;
        ${cond}( Scalar::Util::blessed( \$Nice::Try::EXCEPTION ) && \$Nice::Try::EXCEPTION->isa( '$ex_class' ) && CORE::eval( $eval ) )
        {
            CORE::local \$\@ = \$Nice::Try::EXCEPTION;
            my $ex_var = \$Nice::Try::EXCEPTION;
$catch_code
        }
EOT
                    }
                    elsif( $cdef->{class} )
                    {
                        my $ex_class = $cdef->{class};
                        # Tilmann Haeberle (TH) 2021-03-25: Fix: properly test for exception class inheritance via ->isa
                        $catch_section = <<EOT;
        ${cond}( Scalar::Util::blessed( \$Nice::Try::EXCEPTION ) && \$Nice::Try::EXCEPTION->isa( '$ex_class' ) )
        {
            CORE::local \$\@ = \$Nice::Try::EXCEPTION;
            my $ex_var = \$Nice::Try::EXCEPTION;
$catch_code
        }
EOT
                    }
                    elsif( $cdef->{where} )
                    {
                        my $eval = "q{CORE::local \$_ = \$Nice::Try::EXCEPTION; my $ex_var = \$Nice::Try::EXCEPTION; CORE::local \$\@ = \$Nice::Try::EXCEPTION; $cdef->{where}}";
                        $catch_section = <<EOT;
        ${cond}( CORE::eval( $eval ) )
        {
            CORE::local \$\@ = \$Nice::Try::EXCEPTION;
            my $ex_var = \$Nice::Try::EXCEPTION;
$catch_code
        }
EOT
                    }
                    # No class, just variable assignment like $e or something
                    else
                    {
                        if( ++$else > 1 )
                        {
                            # CORE::warn( "Cannot have more than one falllback catch clause for block: ", $cdef->{block}->content, "\n" ) if( warnings::enabled );
                            CORE::warn( "Cannot have more than one falllback catch clause for block: ", $self->_serialize( $cdef->{block} ), "\n" ) if( warnings::enabled );
                            # Skip, not die. Not fatal, just ignored
                            next;
                        }
                        $cond = "${cond}( 1 )" if( $cond eq 'if' || $cond eq 'elsif' );
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
                # No variable assignment like $e
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
            # End catch loop
            # Tilmann Haeberle (TH) 2021-03-25: Fix: put an else at the end to avoid 'fall_through' issue unless an else exists already
            my $if_end;
            if( $else )
            {
                $if_end = <<EOT;
    }
EOT
            }
            else
            {
                $if_end = <<EOT;
        else
        {
            die( \$Nice::Try::EXCEPTION );
        }
    }
EOT
            }
            $if_end =~ s/\n/ /g unless( $self->{debug_code} );
            push( @$catch_repl, $if_end );
        }
        # No catch clause
        else
        {
            # If the try-catch block is called inside an eval, propagate the exception
            # Otherwise, we just make the $@ available
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
        
        # Add
        my $catch_res = scalar( @$catch_repl ) ? join( '', @$catch_repl ) : '';
        push( @$repl, $catch_res ) if( $catch_res );
        # Closing the If DIED condition
        push( @$repl, "\};" );

        # If there is a catch clause, we put the final block here, if any
        if( $has_catch_clause && CORE::length( $fin_block ) )
        {
            push( @$repl, $fin_block );
        }
        
        # After the finally block has been registered, we will die if catch had a fatal error
        my $catch_dies = <<EOT;
if( defined( \$Nice::Try::CATCH_DIED ) )
{
    die( \$Nice::Try::CATCH_DIED );
}
EOT
        $catch_dies =~ s/\n/ /gs unless( $self->{debug_code} );
        push( @$repl, $catch_dies );
        
        my $last_return_block = <<EOT;
if( ( CORE::defined( \$Nice::Try::WANTARRAY ) || ( defined( \$Nice::Try::BREAK ) && \$Nice::Try::BREAK eq 'return' ) ) and 
    (
      !Scalar::Util::blessed( \$Nice::Try::RETVAL[0] ) or 
      ( Scalar::Util::blessed( \$Nice::Try::RETVAL[0] ) && !\$Nice::Try::RETVAL[0]->isa( 'Nice::Try::SENTINEL' ) ) 
    ) ) 
{
    \$Nice::Try::NEED_TO_RETURN++ if( defined( \$Nice::Try::BREAK ) && \$Nice::Try::BREAK eq 'return' );
    no warnings 'void';
EOT
        if( CORE::scalar( CORE::keys( %warnings:: ) ) && 
            CORE::exists( $warnings::Bits{args_array_with_signatures} ) )
        {
            $last_return_block .= <<EOT;
    no warnings 'experimental::args_array_with_signatures';
EOT
        }
        $last_return_block .= <<EOT;
    if( !CORE::defined( \$Nice::Try::BREAK ) || \$Nice::Try::BREAK eq 'return' )
    {
        if( CORE::defined( \$Nice::Try::WANT ) && CORE::length( \$Nice::Try::WANT ) )
        {
            if( \$Nice::Try::WANT eq 'LIST' )
            {
                \$Nice::Try::NEED_TO_RETURN ? CORE::return( \@Nice::Try::RETVAL ) : \@Nice::Try::RETVAL;
            }
            elsif( \$Nice::Try::WANT eq 'VOID' )
            {
                if( CORE::defined( \$Nice::Try::RETVAL[0] ) && \$Nice::Try::RETVAL[0] eq '__NEXT__' )
                {
                    \$Nice::Try::BREAK = 'next';
                }
                elsif( CORE::defined( \$Nice::Try::RETVAL[0] ) && \$Nice::Try::RETVAL[0] eq '__LAST__' )
                {
                    \$Nice::Try::BREAK = 'last';
                }
                elsif( CORE::defined( \$Nice::Try::RETVAL[0] ) && \$Nice::Try::RETVAL[0] eq '__REDO__' )
                {
                    \$Nice::Try::BREAK = 'redo';
                }
                elsif( defined( \$Nice::Try::BREAK ) && \$Nice::Try::BREAK eq 'return' )
                {
                    \$Nice::Try::NEED_TO_RETURN ? CORE::return( \$Nice::Try::RETVAL[0] ) : \$Nice::Try::RETVAL[0];
                }
            }
            elsif( \$Nice::Try::WANT eq 'OBJECT' )
            {
                \$Nice::Try::NEED_TO_RETURN ? CORE::return( \$Nice::Try::RETVAL[0] ) : \$Nice::Try::RETVAL[0];
            }
            elsif( \$Nice::Try::WANT eq 'REFSCALAR' )
            {
                \$Nice::Try::NEED_TO_RETURN ? CORE::return( \\\$Nice::Try::RETVAL[0] ) : \\\$Nice::Try::RETVAL[0];
            }
            elsif( \$Nice::Try::WANT eq 'SCALAR' )
            {
                \$Nice::Try::NEED_TO_RETURN ? CORE::return( \$Nice::Try::RETVAL[0] ) : \$Nice::Try::RETVAL[0];
            }
            elsif( \$Nice::Try::WANT eq 'BOOLEAN' )
            {
                \$Nice::Try::NEED_TO_RETURN ? CORE::return( \$Nice::Try::RETVAL[0] ) : \$Nice::Try::RETVAL[0];
            }
            elsif( \$Nice::Try::WANT eq 'CODE' )
            {
                \$Nice::Try::NEED_TO_RETURN ? CORE::return( \$Nice::Try::RETVAL[0] ) : \$Nice::Try::RETVAL[0];
            }
            elsif( \$Nice::Try::WANT eq 'HASH' )
            {
                \$Nice::Try::NEED_TO_RETURN ? CORE::return( { \@Nice::Try::RETVAL } ) : { \@Nice::Try::RETVAL };
            }
            elsif( \$Nice::Try::WANT eq 'ARRAY' )
            {
                \$Nice::Try::NEED_TO_RETURN ? CORE::return( \\\@Nice::Try::RETVAL ) : \\\@Nice::Try::RETVAL;
            }
            elsif( \$Nice::Try::WANT eq 'GLOB' )
            {
                \$Nice::Try::NEED_TO_RETURN ? CORE::return( \$Nice::Try::RETVAL[0] ) : \$Nice::Try::RETVAL[0];
            }
        }
        else
        {
            \$Nice::Try::NEED_TO_RETURN ? CORE::return( \$Nice::Try::WANTARRAY ? \@Nice::Try::RETVAL : \$Nice::Try::RETVAL[0] ) : \$Nice::Try::WANTARRAY ? \@Nice::Try::RETVAL : \$Nice::Try::RETVAL[0];
        }
    }
}
elsif( scalar( \@Nice::Try::VOID ) && ( !Scalar::Util::blessed( \$Nice::Try::VOID[0] ) || ( Scalar::Util::blessed( \$Nice::Try::VOID[0] ) && !\$Nice::Try::VOID[0]->isa( 'Nice::Try::SENTINEL' ) ) ) )
{
    no warnings 'void';
    scalar( \@Nice::Try::VOID ) > 1 ? \@Nice::Try::VOID : \$Nice::Try::VOID[0];
}
EOT
        $last_return_block =~ s/\n/ /gs unless( $self->{debug_code} );
        push( @$repl, $last_return_block );
        my $try_catch_code = join( '', @$repl );
        # my $token = PPI::Token->new( "; \{ $try_catch_code \}" ) || die( "Unable to create token" );
        # NOTE: 2021-05-11 (Jacques): Need to remove blocks so that next or last statements can be effective.
        my $envelop = <<EOT;
; CORE::local( \$Nice::Try::BREAK, \@Nice::Try::LAST_VAL ); local \$Nice::Try::NEED_TO_RETURN = 0 unless( defined( \$Nice::Try::NEED_TO_RETURN ) );
\{
__TRY_CATCH_CODE__
\}
if( CORE::defined( \$Nice::Try::BREAK ) )
{
    if( \$Nice::Try::BREAK eq 'next' )
    {
        CORE::next;
    }
    elsif( \$Nice::Try::BREAK eq 'last' )
    {
        CORE::last;
    }
    elsif( \$Nice::Try::BREAK eq 'redo' )
    {
        CORE::redo;
    }
}
no warnings 'void';
CORE::scalar( \@Nice::Try::LAST_VAL ) > 1 ? \@Nice::Try::LAST_VAL : \$Nice::Try::LAST_VAL[0];
EOT
        $envelop =~ s/\n/ /gs unless( $self->{debug_code} );
        $envelop =~ s/__TRY_CATCH_CODE__/$try_catch_code/;
        my $token = PPI::Token->new( $envelop ) || die( "Unable to create token" );
        $token->set_class( 'Structure' );
        my $struct = PPI::Structure->new( $token ) || die( "Unable to create PPI::Structure element" );
        my $orig_try_catch_block = join( '', @$nodes_to_replace );
        my $rc;
        if( !( $rc = $element_before_try->insert_after( $token ) ) )
        {
            $self->_error( "Failed to add replacement code of class '", $token->class, "' after '$element_before_try'" );
            next;
        }
        $self->_message( 3, "Return code is defined? ", defined( $rc ) ? "yes" : "no" ) if( $self->{debug} >= 3 );
        
        for( my $k = 0; $k < scalar( @$nodes_to_replace ); $k++ )
        {
            my $e = $nodes_to_replace->[$k];
            $e->delete || warn( "Could not remove node No $k: '$e'\n" );
        }
    }
    # End foreach catch found
    
    return( $elem );
}

# .Element: [11] class PPI::Token::Word, value caller
# .Element: [11] class PPI::Structure::List, value (1)
#
# ..Element: [12] class PPI::Token::Word, value caller
# ..Element: [12] class PPI::Token::Structure, value ;

sub _process_caller
{
    my $self = shift( @_ );
    my $where = shift( @_ );
    my $elem = shift( @_ ) || return( '' );
    no warnings 'uninitialized';
    return( $elem ) if( !$elem->children );
    foreach my $e ( $elem->elements )
    {
        my $content = $e->content // '';
        my $class = $e->class;
        if( $class eq 'PPI::Token::Word' && $content =~ /^(?:CORE\::)?(?:GLOBAL\::)?caller$/ )
        {
            $e->set_content( 'Nice::Try::caller_' . $where );
        }
        
        if( $e->can('elements') && $e->elements )
        {
            $self->_process_caller( $where => $e );
        }
    }
    return( $elem );
}

sub _process_loop_breaks
{
    my $self = shift( @_ );
    my $elem = shift( @_ ) || return( '' );
    no warnings 'uninitialized';
    return( $elem ) if( !$elem->children );
    my $ct = "$elem";
    # There is nothing to do
    if( index( $ct, 'last' ) == -1 &&
        index( $ct, 'next' ) == -1 &&
        index( $ct, 'redo' ) == -1 &&
        index( $ct, 'goto' ) == -1 &&
        index( $ct, 'return' ) == -1 )
    {
        $self->_message( 4, "There is nothing to be done. Key words last, next, redo or goto are not found." ) if( $self->{debug} >= 4 );
        return( '' );
    }
    $self->_message( 5, "Checking loop breaks in ", scalar( $elem->elements ), " elements for '$elem'" ) if( $self->{debug} >= 5 );
    foreach my $e ( $elem->elements )
    {
        my $content = $e->content // '';
        $self->_messagef( 6, "Checking element: [%d] class %s with %d children and value '%s'\n", $e->line_number, $e->class, ( $e->can('elements') ? scalar( $e->elements ) : 0 ), $content ) if( $self->{debug} >= 6 );
        my $class = $e->class;
        # We found a for, foreach or while loops and we skip, because if there are any break words (next, last, redo) inside, it is not our problem.
        if( $class eq 'PPI::Structure::For' ||
            ( $class eq 'PPI::Statement::Compound' && 
              CORE::defined( $e->first_element->content ) && 
              $e->first_element->content =~ /^(for|foreach|while)$/ ) )
        {
            next;
        }
        elsif( $class eq 'PPI::Token::Word' && $content =~ /^(?:CORE\::)?(?:GLOBAL\::)?(next|last|redo)$/ )
        {
            $self->_message( 5, "Found loop keyword '$content'." ) if( $self->{debug} >= 5 );
            # $e->set_content( qq{CORE::return( '__} . uc( $1 ) . qq{__' )} );
            # $e->set_content( q{$Nice::Try::BREAK='__} . uc( $1 ) . qq{__' ); return;} );
            my $break_code = q{$Nice::Try::BREAK='} . $1 . qq{', return;};
            my $break_doc = PPI::Document->new( \$break_code, readonly => 1 );
            my $new_elem = $break_doc->first_element;
            $new_elem->remove;
            $self->_message( 5, "New element is object '", sub{ overload::StrVal( $new_elem ) }, "' -> $new_elem" ) if( $self->{debug} >= 5 );
            # Not yet implemented as of 2021-05-11 dixit PPI, so we use a hack to make it available anyhow
            $e->replace( $new_elem );
            $self->_message( 5, "Loop keyword now replaced with '$e'." ) if( $self->{debug} >= 5 );
        }
        elsif( $class eq 'PPI::Statement::Break' )
        {
            my $words = $e->find( 'PPI::Token::Word' );
            $self->_messagef( 5, "Found %d word elements inside break element.", scalar( @$words ) ) if( $self->{debug} >= 5 );
            my $word1 = ( scalar( @$words ) ? $words->[0]->content // '' : '' );
            my $word2 = ( scalar( @$words ) > 1 ? $words->[1]->content // '' : '' );
            $self->_message( 5, "Word 1 -> ", $word1 ) if( $self->{debug} >= 5 );
            $self->_message( 5, "Word 2 -> ", $word2 ) if( $self->{debug} >= 5 && scalar( @$words ) > 1 );
            # If we found a break word without a label, i.e. next, last, redo, 
            # we replace it with a special return statement
            if( (
                  scalar( @$words ) == 1 ||
                  ( scalar( @$words ) > 1 && $word2 =~ /^(for|foreach|given|if|unless|until|while)$/ ) ||
                  $word1 eq 'return'
                ) && 
                (
                  $word1 eq 'next' ||
                  $word1 eq 'last' ||
                  $word1 eq 'redo' ||
                  $word1 eq 'return'
                ) )
            {
                # We add our special return value. Notice that we use 'return' and not 
                # 'CORE::return'. See below why.
                # my $break_code = qq{return( '__} . uc( $word1 ) . qq{__' )};
                my $break_code = q{$Nice::Try::BREAK='} . $word1 . ( $word1 eq 'return' ? "', $e" : qq{', return} );
                # e.g. next if( $i == 2 );
                # next and if are both treated as 'word' by PPI
                if( scalar( @$words ) > 1 )
                {
                    ( my $ct = $e->content ) =~ s/^(next|last|redo)//;
                    $break_code .= $ct;
                }
                else
                {
                    $break_code .= ';'
                }
                $self->_message( 5, "Replacing this node with: $break_code" ) if( $self->{debug} >= 5 );
                
                my $break_doc = PPI::Document->new( \$break_code, readonly => 1 );
                my $new_elem = $break_doc->first_element;
                $new_elem->remove;
                $self->_message( 5, "New element is object '", sub{ overload::StrVal( $new_elem ) }, "' -> $new_elem" ) if( $self->{debug} >= 5 );
                # Not yet implemented as of 2021-05-11 dixit PPI, so we use a hack to make it available anyhow
                $self->_message( 5, "Updated element now is '$e' for class '", $e->class, "' and parent class '", $e->parent->class, "'." ) if( $self->{debug} >= 5 );
                $e->replace( $new_elem );
                # 2021-05-12 (Jacques): I have to do this workaround, because weirdly enough
                # PPI (at least with PPI::Node version 1.270) will refuse to add our element
                # if the 'return' word is 'CORE::return' so, we add it without and change it after
                # $new_elem->first_element->set_content( 'CORE::return' );
            }
            next;
        }
        elsif( $class eq 'PPI::Token::Word' && 
               ( $e->content // '' ) eq 'return' &&
               $e->sprevious_sibling &&
               # Should be enough
               $e->sprevious_sibling->class eq 'PPI::Token::Operator' )
               # $e->sprevious_sibling->class eq 'PPI::Token::Operator' &&
               # ( $e->sprevious_sibling->content // '' ) =~ /^$/ )
        {
            my $break_code;
            my @to_remove;
            # return( # something );
            if( $e->snext_sibling &&
                $e->snext_sibling->class eq 'PPI::Structure::List' )
            {
                my $list = $e->snext_sibling;
                push( @to_remove, $list );
                $break_code = "return( \$Nice::Try::RETURN->${list} )";
            }
            # return( "" ) or return( '' )
            elsif( $e->snext_sibling && 
                   $e->snext_sibling->isa( 'PPI::Token::Quote' ) )
            {
                my $list = $e->snext_sibling;
                push( @to_remove, $list );
                $break_code = "return( \$Nice::Try::RETURN->(${list}) );";
            }
            # return;
            elsif( $e->snext_sibling && 
                   $e->snext_sibling->class eq 'PPI::Token::Structure' &&
                   $e->snext_sibling->content eq ';' )
            {
                $break_code = "return( \$Nice::Try::RETURN->() );";
            }
            else
            {
                my $list = '';
                my $next_elem;
                my $prev_elem = $e;
                while( $next_elem = $prev_elem->snext_sibling )
                {
                    last if( $next_elem->content eq ';' );
                    $list .= $next_elem->content;
                    push( @to_remove, $next_elem );
                    $prev_elem = $next_elem;
                }
                $break_code = "return( \$Nice::Try::RETURN->(${list}) );";
            }
            my $break_doc = PPI::Document->new( \$break_code, readonly => 1 );
            my $new_elem = $break_doc->first_element;
            $new_elem->remove;
            $self->_message( 5, "New element is object '", sub{ overload::StrVal( $new_elem ) }, "' -> $new_elem" ) if( $self->{debug} >= 5 );
            # Not yet implemented as of 2021-05-11 dixit PPI, so we use a hack to make it available anyhow
            $e->replace( $new_elem );
            $_->remove for( @to_remove );
        }
        
        if( $e->can('elements') && $e->elements )
        {
            $self->_process_loop_breaks( $e );
        }
    }
    return( $elem );
}

sub _process_sub_token
{
    my $self = shift( @_ );
    my $elem = shift( @_ ) || return( '' );
    # token __SUB__ is only available since perl v5.16
    return( '' ) unless( $] >= 5.016000 );
    if( index( "$elem", '__SUB__' ) == -1 )
    {
        $self->_message( 5, "No __SUB__ token found in ", scalar( $elem->elements ), " elements for '$elem'" ) if( $self->{debug} >= 5 );
        return( '' );
    }
    no warnings 'uninitialized';
    return( $elem ) if( !$elem->children );
    $self->_message( 5, "Checking __SUB__ token in ", scalar( $elem->elements ), " elements for '$elem'" ) if( $self->{debug} >= 5 );
    # Look for parent, and if we can find a sub, or an anonymous sub
    # my $sub = sub{} -> PPI::Token::Word 'sub', PPI::Structure::Block '{'
    # sub mysub {} -> PPI::Statement::Sub -> PPI::Token::Word 'sub', PPI::Token::Word 'mysub', PPI::Structure::Block '{'
    my $find_closest_sub;
    $find_closest_sub = sub
    {
        my $e = shift( @_ );
        return if( !defined( $e ) );
        my $parent = $e->parent;
        return if( !$parent );
        # Keep going up until we find a block
        while( $parent )
        {
            $self->_message( 5, "Checking parent element of class ", $parent->class, " and value $parent" ) if( $self->{debug} >= 5 );
            if( $parent->class eq 'PPI::Structure::Block' )
            {
                my $sub_name;
                my $prev = $parent->sprevious_sibling;
                while( $prev )
                {
                    if( $prev->content eq 'sub' )
                    {
                        return({ element => $parent, name => $sub_name });
                    }
                
                    if( $prev->class eq 'PPI::Token::Word' )
                    {
                        if( CORE::defined( $sub_name ) )
                        {
                            warn( "Found some redefinition of a subroutine's name at line ", $prev->line_number, " for subroutine '${sub_name}'\n" ) if( warnings::enabled() );
                        }
                        $sub_name = $prev->content;
                    }
                    $prev = $prev->sprevious_sibling;
                }
            }
            $parent = $parent->parent;
        }
        return;
    };
    my $def = $find_closest_sub->( $elem );
    if( $def )
    {
        my $block = $def->{element};
        $self->_message( 5, "Found a sub block at line ", $block->line_number, " of class ", $block->class, " with name '", ( $def->{name} // 'anonymous' ), "'" ) if( $self->{debug} >= 5 );
        my $sub_token_code = <<'PERL';
CORE::local $Nice::Try::SUB_TOKEN;
{
    use feature 'current_sub';
    no warnings 'experimental';
    $Nice::Try::SUB_TOKEN = __SUB__;
}
PERL
        $sub_token_code =~ s/\n//gs;
#         $sub_token_code .= $block;
        my $sub_token_doc = PPI::Document->new( \$sub_token_code, readonly => 1 );
        my @new_elems = $sub_token_doc->elements;
        # my $new_elem = $sub_token_doc;
        # $new_elem->remove;
        $_->remove for( @new_elems );
        $self->_message( 5, "New elements is object '", sub{ join( ', ', map( overload::StrVal( $_ ), @new_elems ) ) }, "' -> $_" ) if( $self->{debug} >= 5 );
        # $block->replace( $new_elem );
        # Not yet implemented as of 2021-05-11 dixit PPI, so we use a hack to make it available anyhow
        my $rv;
        my @children = $block->children;
        if( scalar( @children ) )
        {
            my $last = $children[0];
            for( reverse( @new_elems ) )
            {
                $rv = $last->__insert_before( $_ );
                $self->_message( 5, "Element successfully inserted? ", ( defined( $rv ) ? ( $rv ? 'yes' : 'no' ) : 'no. element provided was not an PPI::Element.' ) ) if( $self->{debug} >= 5 );
                $last = $_;
            }
        }
        else
        {
            for( @new_elems )
            {
                $rv = $block->add_element( $_ );
                $self->_message( 5, "Element successfully inserted? ", ( defined( $rv ) ? ( ref( $rv ) eq 'PPI::Element' ? 'ok' : 'returned value is not an PPI::Element (' . ref( $rv ) . ')' ) : 'no' ) ) if( $self->{debug} >= 5 );
            }
        }
        $self->_message( 5, "Updated block now is '$block' for class '", $block->class, "'." ) if( $self->{debug} >= 5 );
    }
    else
    {
        $self->_message( 5, "No subroutine found! This is a try-catch block outside of a subroutine." ) if( $self->{debug} >= 5 );
    }
    
    my $crawl;
    $crawl = sub
    {
        my $this = shift( @_ );
        foreach my $e ( $this->elements )
        {
            $self->_message( 5, "Checking element ", overload::StrVal( $e ), " of class ", $e->class, " for token __SUB__" ) if( $self->{debug} >= 5 );
            if( $e->content eq '__SUB__' )
            {
                $self->_message( 5, "Found token __SUB__" ) if( $self->{debug} >= 5 );
                my $new_ct = '$Nice::Try::SUB_TOKEN';
                my $new_ct_doc = PPI::Document->new( \$new_ct, readonly => 1 );
                my $new_token = $new_ct_doc->first_element;
                $new_token->remove;
                $e->replace( $new_token );
            }
            elsif( $e->can( 'elements' ) &&
                scalar( $e->elements ) && 
                index( "$e", '__SUB__' ) != -1 )
            {
                $crawl->( $e );
            }
        }
    };
    $crawl->( $elem );
    $self->_message( 5, "After processing __SUB__ tokens, try-catch block is now:\n$elem" ) if( $self->{debug} >= 5 );
    return( $elem );
}

# Taken from PPI::Document
sub _serialize 
{
    my $self   = shift( @_ );
    my $ppi    = shift( @_ ) || return( '' );
    no warnings 'uninitialized';
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
    # NOTE: Nice::Try::ScopeGuard class
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
        my( $code, $args, $catch_err ) = @{ $_[0] };
        # save the current exception to make it available in the finally sub,
        # and to restore it after the eval
        my $err = defined( $catch_err ) ? $catch_err : $@;
        local $@ if( UNSTABLE_DOLLARAT );
        $@ = $catch_err if( defined( $catch_err ) );
        CORE::eval 
        {
            $@ = $err;
            $code->( @$args );
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

{
    # NOTE: Nice::Try::ObjectContext
    package
        Nice::Try::ObjectContext;

    sub new
    {
        my $that = shift( @_ );
        return( bless( { val => [@_] } => ( ref( $that ) || $that ) ) );
    }

    sub callback
    {
        my $self = shift( @_ );
        return( $self->{val}->[0] );
    }
}

{
    # NOTE: PPI::Element
    package
        PPI::Element;
    
    no warnings 'redefine';
    sub replace {
        my $self    = ref $_[0] ? shift : return undef;
        # If our object and the other are not of the same class, PPI refuses to replace 
        # to avoid damages to perl code
        # my $other = _INSTANCE(shift, ref $self) or return undef;
        my $other = shift;
        # die "The ->replace method has not yet been implemented";
        $self->parent->__replace_child( $self, $other );
        1;
    }
}

1;

# NOTE POD
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
        return( "Caught an exception $e" );
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

Also since version 1.0.0, L<Nice::Try> is B<extended> context aware:

    use Want; # an awesome module which extends wantarray
    sub info
    {
        my $self = shift( @_ );
        try
        {
            # Do something
            if( want('OBJECT') )
            {
                return( $self );
            }
            elsif( want('CODE') )
            {
                # dummy code ref for example
                return( sub{ return( $name ); } );
            }
            elsif( want('LIST') )
            {
                return( @some_data );
            }
            elsif( want('ARRAY') )
            {
                return( \@some_data );
            }
            elsif( want('HASH') )
            {
                return({ name => $name, location => $city });
            }
            elsif( want('REFSCALAR') )
            {
                return( \$name );
            }
            elsif( want('SCALAR' ) )
            {
                return( $name ); # regular string
            }
            elsif( want('VOID') )
            {
                return;
            }
        }
        catch( $e )
        {
            $Logger->( "Caught exception: $e" );
        }
    }

    # regular string context
    my $name = $o->info;
    # code context
    my $name = $o->info->();
    # list context like wantarray
    my @data = $o->info;
    # hash context
    my $name = $o->info->{name};
    # array context
    my $name = $o->info->[2];
    # object context
    my $name = $o->info->another_method;
    # scalar reference context
    my $name = ${$o->info};

And you also have granular power in the catch block to filter which exception to handle. See more on this in L</"EXCEPTION CLASS">

    try
    {
        die( Exception->new( "Arghhh" => 401 ) );
    }
    # can also write this as:
    # catch( Exception $oopsie where { $_->message =~ /Arghhh/ && $_->code == 500 } )
    catch( $oopsie isa Exception where { $_->message =~ /Arghhh/ && $_->code == 500 } )
    {
        # Do something to deal with some server error
    }
    catch( $oopsie isa Exception where { $_->message =~ /Arghhh/ && $_->code == 401 } )
    {
        # should reach here.
    }
    catch( $oh_well isa("Exception") ) # or you can also write catch( Exception $oh_well )
    {
        # Default using another way to filter by Exception
    }
    catch( $oopsie where { /Oh no/ } )
    {
        # Do something based on the value of a simple error; not an exception class
    }
    # Default
    catch( $default )
    {
        print( "Unknown error: $default\n" );
    }

=head1 VERSION

    v1.3.13

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

=item * C<catch> can filter by exception class. For example:

    try
    {
        die( My::Exception->new( "Not alllowed here.", { code => 401 }) );
    }
    catch( My::Exception $e where { $_->code == 500 })
    {
        print( "Oopsie\n" );
    }
    catch( My::Exception $e where { $_->code == 401 })
    {
        print( "Get away!\n" );
    }
    catch( My::Exception $e )
    {
        print( "Got an exception: $e\n" );
    }
    catch( $default )
    {
        print( "Something weird has happened: $default\n" );
    }
    finally
    {
        $dbh->disconnect;
    }

See more on this in L</"EXCEPTION CLASS">

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

=item * C<try> or C<catch> blocks can contain flow control keywords such as C<next>, C<last> and C<redo>

    while( defined( my $product = $items->[++$i] ) )
    {
        try
        {
            # Do something
            last if( !$product->active );
        }
        catch( $oops )
        {
            $log->( "Error: $oops" );
            last;
        }
    }
    continue
    {
        try
        {
            if( $product->region eq 'Asia' )
            {
                push( @asia, $product );
            }
            else
            {
                next;
            }
        }
        catch( $e )
        {
            $log->( "An unexpected error has occurred. Is $product an object? $e" );
            last;
        }
    }

=item * Can be used with or without a C<catch> block

=item * Supports a C<finally> block called in void context for cleanup for example. The C<finally> block will always be called, if present.

    #!/usr/local/bin/perl
    use v5.36;
    use strict;
    use warnings;
    use Nice::Try;
    
    try
    {
        die( "Oops" );
    }
    catch( $e )
    {
        say "Caught an error: $e";
        die( "Oops again" );
    }
    finally
    {
        # Some code here that will be executed after the catch block dies
        say "Got here in finally with \$\@ -> $@";
    }

The above would yield something like:

    Caught error: Oops at ./test.pl line 9.
    Oops again at ./test.pl line 14.
    Got here in finally with $@ -> Oops again at ./test.pl line 14.

=item * L<Nice::Try> is rich context aware, which means it can provide you with a super granular context on how to return data back to the caller based on the caller's expectation, by using a module like L<Want>.

=item * Call to L<perlfunc/caller> will return the correct entry in call stack

    #!/usr/bin/perl
    BEGIN
    {
        use strict;
        use warnings;
        use Nice::Try;
    };

    {
        &callme();
    }

    sub callme
    {
        try
        {
            my @info = caller(1); # or my @info = caller;
            print( "Called from package $info[0] in file $info[1] at line $info[2]\n" );
        }
        catch( $e )
        {
            print( "Got an error: $e\n" );
        }
    }

Will yield: C<Called from package main in file ./test.pl at line 10>

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

For example L<Syntax::Keyword::Try> and now perl with L<version 5.34.0 using experimental feature|https://perldoc.perl.org/5.34.0/perldelta#Experimental-Try/Catch-Syntax>.

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

In group 3, L<TryCatch> was working wonderfully, but was relying on L<Devel::Declare> which was doing some esoteric stuff and eventually the version 0.006020 broke L<TryCatch> and there seems to be no intention of correcting this breaking change. Besides, L<Devel::Declare> is now marked as deprecated and its use is officially discouraged.

L<TryCatch> does not support any C<finally> block.

In group 4, there is L<Syntax::Keyword::Try>, which is a great alternative if you do not care about exception class filter (it supports class exception since 2020-07-21 with version 0.15 and variable assignment since 2020-08-01 with version 0.18).

Although, the following script would not work under L<Syntax::Keyword::Try> :

    BEGIN
    {
        use strict;
        use warnings;
        use Syntax::Keyword::Try;
    };

    {
        &callme();
    }

    sub callme
    {
        try {
            print( "Hello there\n" );
        }
        catch ($e) {
            print( "Got an error: $e\n" );
        }
    }

This will trigger the following error:

    syntax error at ./test.pl line 18, near ") {"
    syntax error at ./test.pl line 21, near "}"
    Execution of ./test.pl aborted due to compilation errors.

That is because L<Syntax::Keyword::Try> expects to be C<used> outside of a BEGIN block like this:

    use strict;
    use warnings;
    use Syntax::Keyword::Try;

    # Rest of the script, same as above

Of course, with L<Nice::Try>, there is no such constraint. You can L<perlfunc/use> L<Nice::Try> inside or outside of a C<BEGIN> block indistinctively.

Since L<perl version 5.33.7|https://perldoc.perl.org/blead/perlsyn#Try-Catch-Exception-Handling> and now in L<perl v5.34.0|https://perldoc.perl.org/5.34.0/perldelta#Experimental-Try/Catch-Syntax> you can use the try-catch block using an experimental feature which may be removed in future versions, by writing:

    use feature 'try'; # will emit a warning this is experimental

This new feature supports try-catch block and variable assignment, but no exception class, nor support for C<finally> block until version L<perl 5.36 released on 2022-05-28|https://perldoc.perl.org/5.36.0/perldelta> of perl, so you can do:

    try
    {
        # Oh no!
        die( "Argh...\n" );
    }
    catch( $oh_well )
    {
        return( $self->error( "Something went awry: $oh_well" ) );
    }

But B<you cannot do>:

    try
    {
        # Oh no!
        die( MyException->new( "Argh..." ) );
    }
    catch( MyException $oh_well )
    {
        return( $self->error( "Something went awry with MyException: $oh_well" ) );
    }
    # Support for 'finally' has been implemented in perl 5.36 released on 2022-05-28
    finally
    {
        # do some cleanup here
    }

An update as of 2022-05-28, L<perl-v5.36|https://perldoc.perl.org/5.36.0/perldelta#try/catch-can-now-have-a-finally-block-(experimental)> now supports the experimental C<finally> block.

Also, the C<use feature 'try'> expression must be in the relevant block where you use C<try-catch>. You cannot just put it in your C<BEGIN> block at the beginning of your script. If you have 3 subroutines using C<try-catch>, you need to put C<use feature 'try'> in each of them. See L<perl documentation on lexical effect|https://perldoc.perl.org/feature#Lexical-effect> for more explanation on this.

It is probably a matter of time until this is fully implemented in perl as a regular non-experimental feature.

See more information about perl's featured implementation of try-catch in L<perlsyn|https://perldoc.perl.org/perlsyn#Try-Catch-Exception-Handling>

So, L<Nice::Try> is quite unique and fills the missing features, and since it uses XS modules for a one-time filtering, it is quite fast.

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

=head1 CATCHING OR NOT CATCHING?

L<Nice::Try> can be used with a single C<try> block which will, in effect, behaves like an eval and the special variable C<$@> will be available as always.

    try
    {
        die( "Oh no, something went wrong!\n" );
    }
    print( "Got here with $@\n" );

or even:

    try
    {
        die( "Oh no, something went wrong!\n" );
    }
    catch( $e ); # Not very meaningful, but it will work
    print( "Got here with $@\n" );

However, if you decide to catch class exceptions, make sure to add a default C<catch( $e )>. For example:

    try
    {
        die( MyException->new( "Oh no" ) );
    }
    print( "Got here with $@\n" );

will work and C<print> will display "Got here with Oh no". However:

    try
    {
        die( MyException->new( "Oh no" ) );
    }
    catch( Some::Exception $e )
    {
        # won't reach here
    }

will make your process die because of the exception not being caught, thus you might want to do instead:

    try
    {
        die( MyException->new( "Oh no" ) );
    }
    catch( Some::Exception $e )
    {
        # won't reach here
    }
    catch( $default )
    {
        print( "Got you! Error was: $default\n" );
    }

And the last catch will catch the exception.

Since, try-catch block can be nested, the following would work too:

    try
    {
        try
        {
            die( MyException->new( "Oh no" ) );
        }
        catch( Some::Exception $e )
        {
            # won't reach here
        }
    }
    catch( MyException $e )
    {
        print( "Got you! MyException was: $e\n" );
    }
    # to play it safe
    catch( $e )
    {
        # do something about it
    }

=head1 EXCEPTION CLASS

As mentioned above, you can use class when raising exceptions and you can filter them in a variety of ways when you catch them.

Here are your options (replace C<Exception::Class> with your favorite exception class):

=over 4

=item 1. catch( Exception::Class $error_variable ) { }

=item 2. catch( Exception::Class $error_variable where { $condition } ) { }

Here C<$condition> could be anything that fits in a legitimate perl block, such as:

    try
    {
        die( Exception->new( "Oh no!", { code => 401 } ) );
    }
    catch( Exception $oopsie where { $_->code >= 400 && $_->code <= 499 })
    {
        # some more handling here
    }

In the condition block C<$_> will always be made available and will correspond to the exception object thrown, just like C<$oopsie> in this example. C<$@> is also available with the exception object as its value.

=item 3. catch( $e isa Exception::Class ) { }

This is a variant of the C<catch( Exception::Class $e ) {}> form

=item 4. catch( $e isa('Exception::Class') ) { }

A variant of the one above if you want to use single quotes.

=item 5. catch( $e isa("Exception::Class") ) { }

A variant of the one above if you want to use double quotes.

=item 6. catch( $e isa Exception::Class where { $condition } ) { }

=item 7. catch( $e isa('Exception::Class') where { $condition } ) { }

=item 8. catch( $e isa("Exception::Class") where { $condition } ) { }

=item 9. catch( $e where { $condition } ) { }

This is not a class exception catching, but worth mentioning. For example:

    try
    {
        die( "Something bad happened.\n" );
    }
    catch( $e where { /something bad/i })
    {
        # Do something about it
    }
    catch( $e )
    {
        # Default here
    }

=back

=head1 LOOPS

Since version v0.2.0 L<Nice::Try> supports the use of flow control keywords such as C<next>, C<last> and C<redo> inside try-catch blocks. For example:

    my @names = qw( John Jack Peter Paul Mark );
    for( $i..$#names )
    {
        try
        {
            next if( $i == 2 );
            # some more code...
        }
        catch( $e )
        {
            print( "Got exception: $e\n" );
        }
    }

It also works inside the catch block or inside the C<continue> block:

    while( defined( my $product = $items->[++$i] ) )
    {
        # Do something
    }
    continue
    {
        try
        {
            if( $product->region eq 'Asia' )
            {
                push( @asia, $product );
            }
            else
            {
                next;
            }
        }
        catch( $e )
        {
            $log->( "An unexpected error has occurred. Is $product an object? $e" );
            last;
        }
    }

Control flow with labels also work

    ELEM: foreach my $n ( @names )
    {
        try
        {
            $n->moveAfter( $this );
            next ELEM if( $n->value == 1234567 );
        }
        catch( $oops )
        {
            last ELEM;
        }
    }

However, if you enclose a try-catch block inside another block, use of C<next>, C<last> or C<redo> will silently not work. This is due to perl control flow. See L<perlsyn> for more information on this. For example, the following would not yield the desired outcome:

    ELEM: foreach my $n ( @names )
    {
        { # <--- Here is the culprit
            try
            {
                $n->moveAfter( $this );
                # This next statement will not do anything.
                next ELEM if( $n->value == 1234567 );
            }
            catch( $oops )
            {
                # Neither would this one.
                last ELEM;
            }
        }
    }

=head1 CONTEXT AWARENESS

L<Nice::Try> provides a high level of granularity about the context in which your subroutine was called.

Normally, you would write something like this, and it works as always:

    sub info
    {
        try
        {
            # do something here
            if( wantarray() )
            {
                return( @list_of_values );
            }
            # caller just want a scalar
            elsif( defined( wantarray() ) )
            {
                return( $name );
            }
            # otherwise if undefined, it means we are called in void context, like:
            # $o->info; with no expectation of return value
        }
        catch( $e )
        {
            print( "Caught an error: $e\n" );
        }
    }

The above is nice, but how do you differentiate cases were your caller wants a simple returned value and the one where the caller wants an object for chaining purpose, or if the caller wants an hash or array reference in return?

For example:

    my $val = $o->info->[2]; # wants an array reference
    my $val = $o->info->{name} # wants an hash reference
    # etc...

Now, you can do the following:

    use Want; # an awesome module which extends wantarray
    sub info
    {
        my $self = shift( @_ );
        try
        {
            # Do something
            # 
            # same as wantarray() == 1
            if( want('LIST') )
            {
                return( @some_data );
            }
            # same as: if( defined( wantarray() ) && !wantarray() )
            elsif( want('SCALAR' ) )
            {
                return( $name ); # regular string
            }
            # same as if( !defined( wantarray() ) )
            elsif( want('VOID') )
            {
                return;
            }
            # For the other contexts below, wantarray is of no help
            if( want('OBJECT') )
            {
                return( $obj ); # useful for chaining
            }
            elsif( want('CODE') )
            {
                # dummy code ref for example
                return( sub{ return( $name ); } );
            }
            elsif( want('ARRAY') )
            {
                return( \@some_data );
            }
            elsif( want('HASH') )
            {
                return({ name => $name, location => $city });
            }
        }
        catch( $e )
        {
            $Logger->( "Caught exception: $e" );
        }
    }

Thus this is particularly useful if, for example, you want to differentiate if the caller just wants a return string, or an object for chaining.

L<perlfunc/wantarray> would not know the difference, and other try-catch implementation would not let you benefit from using L<Want>.

For example:

    my $val = $o->info; # simple regular scalar context; but...
    # here, we are called in object context and wantarray is of no help to tell the difference
    my $val = $o->info->another_method;

Other cases are:

    # regular string context
    my $name = $o->info;
    # list context like wantarray
    my @data = $o->info;

    # code context
    my $name = $o->info->();
    # hash context
    my $name = $o->info->{name};
    # array context
    my $name = $o->info->[2];
    # object context
    my $name = $o->info->another_method;

See L<Want> for more information on how you can benefit from it.

Currently lvalues are not implemented and will be in future releases. Also note that L<Want> does not work within tie-handlers. It would trigger a segmentation fault. L<Nice::Try> detects this and disable automatically support for L<Want> if used inside a tie-handler, reverting to regular L<perlfunc/wantarray> context.

Also, for this rich context awareness to be used, obviously try-catch would need to be inside a subroutine, otherwise there is no rich context other than the one the regular L<perlfunc/wantarray> provides.

This is particularly true when running within an Apache modperl handler which has no caller. If you use L<Nice::Try> in such handler, it will kill Apache process, so you need to disable the use of L<Want>, by calling:

    use Nice::Try dont_want => 1;

When there is an update to correct this bug from L<Want>, I will issue a new version.

The use of L<Want> is also automatically disabled when running under a package that use overloading.

=head1 LIMITATIONS

Before version C<v1.3.5>, there was a limitation on using signature on a subroutine, but since version C<v1.3.5>, it has been fixed and there is no more any limitation. Thus the following works nicely too.

    use strict;
    use warnings;
    use experimental 'signatures';
    use Nice::Try;

    sub test { 1 }

    sub foo ($f = test()) { 1 }

    try {
        my $k = sub ($f = foo()) {}; # <-- this sub routine attribute inside try-catch block used to disrupt Nice::Try and make it fail.
        print( "worked\n" );
    }
    catch($e) {
        warn "caught: $e";
    }

    __END__

=head1 PERFORMANCE

C<Nice::Try> is quite fast, but as with any class implementing a C<try-catch> block, it is of course a bit slower than the natural C<eval> block.

Because C<Nice::Try> relies on L<PPI> for parsing the perl code, if your code is very long, there will be an execution time penalty.

If you use framework such as L<mod_perl2>, then it will only affect the first time the code is run, since afterward, the code will be loaded in memory.

Still, if you use perl version C<v5.34> or higher, and have simple need of C<try-catch>, then simply use instead perl experimental implementation, such as:

    use v5.34;
    use strict;
    use warnings;
    use feature 'try';
    no warnings 'experimental';

    try
    {
        # do something
    }
    catch( $e )
    {
        # catch fatal error here
    }

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

=head1 CLASS FUNCTIONS

The following class functions can be used.

=head2 implement

    my $new_code = Nice::Try->implement( $perl_code );
    eval( $new_code );

Provided with a perl code having one or more try-catch blocks and this will return a perl code converted to support try-catch blocks.

This is designed to be used for perl code you store, such as subroutines dynamically loaded or eval'ed.

For example:

    my $code = Nice::Try->implement( <<EOT );
    sub $method
    {
        my \$self = shift( \@_ );
        try
        {
            # doing something that may die here
        }
        catch( \$e )
        {
            return( \$self->error( "Oops: \$e ) );
        }
    }
    EOT

You can also pass an optional hash or hash reference of options to L</implement> and it will be used to instantiate a new L<Nice::Try> method. The options accepted are the same ones that can be passed when using C<use Nice::Try>

=head1 CREDITS

Credits to Stephen R. Scaffidi for his implementation of L<Try::Harder> from which I initially borrowed some code.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<PPI>, L<Filter::Util::Call>, L<Try::Harder>, L<Syntax::Keyword::Try>, L<Exception::Class>

L<JavaScript implementation of nice-try|https://javascript.info/try-catch>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2020-2024 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated files under the same terms as Perl itself.

=cut
