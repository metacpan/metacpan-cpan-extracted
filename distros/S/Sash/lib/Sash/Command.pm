package Sash::Command;
use strict;
use warnings;

use Sash::CommandHash;
use Sash::Buffer;
use Sash::Table;
use Sash::Timer;
use Sash::ResultHistory;
use Sash::Properties;

use Carp;

use Data::Dumper;

# Singleton implementation of the Mediator Pattern

my $_valid = 0;
my $_use_timer = 0;
my $_writing_query;
my $_large_query_size = 5000;

tie my $_buffer, 'Sash::Buffer';

sub writing_query {
    my $class = shift;
    return $_writing_query = ( shift || $_writing_query );
}

sub large_query_size {
    my $class = shift;
    return $_large_query_size = ( shift || $_large_query_size );
}

sub begin {
    my $class = shift;
    my $args = shift; #hash ref

    # Reset whether to use the timer for the command in indicate we have been
    # properly invoked
    $_use_timer = 1;
    $_valid = 1;

    if ( defined $args->{no_timer} ) {
        $_use_timer = 0;
    } else {
        Sash::Timer->start;
    }
    
    return;
}

sub end {
    my $class = shift;
    my $args = shift; #hash ref

    croak 'Improper class usage!  Must call begin method.' unless $_valid;

    Sash::Timer->stop if $_use_timer;

    # Reset ourselves for the next invocation
    $_valid = 0;
    
    return $args->{result} if defined $args->{result} && Sash::Properties->output eq Sash::Properties->perlval;

    # Plan for other independent operations
    if ( defined $args->{result} ) {
        croak 'Result not of type Sash::Table' unless ref $args->{result} eq 'Sash::Table';

        my $table = $args->{result};

        # We are responsible first for adding the result to the history...
        Sash::ResultHistory->add( $table );

        # and then displaying the result back to the user.
        $table->display( ( $_use_timer ) ? Sash::Timer->elapsed : undef );
    }

    return;
}

sub get_command_hash {
    my $class = shift;

    my $command_hash = Sash::CommandHash->new( 'Sash::Command' );

    return {
        'clear' => $command_hash->build( { use => 'clear' } ),
        #'connect' => $command_hash->build( { use => 'connect' } ),
        'edit' => $command_hash->build( { use => 'edit_buffer', proc => 'meth' } ),
        'help' => $command_hash->build( { use => 'help', proc => 'meth' } ),
        'history' => $command_hash->build( { use => 'history', proc => 'meth' } ),
        'list' => $command_hash->build( { use => 'list' } ),
        'quit' => $command_hash->build( { use => 'quit', proc => 'meth' } ),
        'reconnect' => $command_hash->build( { use => 'reconnect' } ),
        'result' => {
            'cmds' => {
                # 'head' => get_command_hash( { use => 'head' } ),
                # 'tail' => get_command_hash( { use => 'tail' } ),
                'all' => $command_hash->build( { use => 'all' } ),
                # Add args to this so you can say: result limit -s 100 100
                'limit' => $command_hash->build( { use => 'limit' } ),
                'revert' => $command_hash->build( { use => 'revert' } ),
                #'grep' => get_command_hash( { use => 'grep', proc => 'meth' } ),
                'search' => $command_hash->build( { use => 'search' } ),
                'sort' => $command_hash->build( { use => 'sort', proc => 'meth' } ),
                'undo' => $command_hash->build( { use => 'undo' } ),
                'redo' => $command_hash->build( { use => 'redo' } ),
            },      
        },      
        'set' => {
            'cmds' => {
                'output' => $command_hash->build( { use => 'set_output' } ),
            }
        },
        'x' => $command_hash->build( { use => 'x' } ),
        'q' => { syn => "quit" },
        'c' => { syn => 'clear' },
        'e' => { syn => 'edit' },
        'l' => { syn => 'list' },
        'exit' => { syn => "quit" },
    };
}

# Adapter for commands the need the elapsed time after they call end;
sub elapsed {
    my $class = shift;

    return Sash::Timer->elapsed;
}

sub AUTOLOAD {
    my $command_class = Sash::Plugin::Factory->get_plugin_command_class;
    my @plugin_methods = Sash::Plugin::Factory->get_plugin_command_hash;

    our $AUTOLOAD;

    if ( $AUTOLOAD =~ /::(\w+)$/ && grep { $1 eq $_ } @plugin_methods ) {
        my $method_to_invoke = "${1}_meth";
        $method_to_invoke = "${1}_proc" unless $command_class->can( $method_to_invoke );
        $command_class->$method_to_invoke( shift );
    }
}

sub default_command {
    my $class = shift;
    my $term = shift;
    my $args = shift;

    if ( $_writing_query ) {
        ( my $query = $args->{rawline} ) =~ s/;$//g;
        
        # Remember this is tied :)
        $_buffer .= $query;
        
        if ( $args->{rawline} =~ /;$/ ) {
            Sash::Command->execute_query( $term, $_buffer, $args->{cursor_class} );
            $_writing_query = 0;
            $term->set_standard_prompt;
        }
    } else {
        no strict;

        # The following is done so that user's of sash can write scripts at the prompt
        # and then copy them to their real destination
        ( my $command = $args->{rawline} ) =~ s/\$client->//ig;
        eval $command;
        croak $@ if $@;
    }

    return;
}

sub _getCallerArgs {
    my $self = shift;
    my $invoked_by = shift;
    my $method_args = shift;
    my $rawline_replace = shift;

    my $caller_args;

    # We get a different type of argument depending on who invoked us.  There
    # are 2 valid classes that can invoke us:
    #
    # 1) Sash::Terminal->call_cmd
    # 2) Sash::Command->AUTOLOAD which makes it look like we got invoked by
    #        Sash::Plugin::VerticalResponse::Command->getXXX_meth
    if ( $invoked_by->isa( 'Sash::Terminal' ) ) {
        ( $caller_args = $method_args->{rawline} ) =~ s/$rawline_replace\s*(.*);?$/$1/;
    } elsif ( $invoked_by->isa( 'Sash::Command' ) ) {
        $caller_args = $method_args;
    } else {
        croak "Invalid Invocation";
    }

    return $caller_args;
}


sub _bringVarIntoScope {
    my $self = shift;
    my $user_defined_var = shift;
    
    return undef unless defined $user_defined_var;
    
    my $var;
    
    # We don't play nice with arrays and hashes, but do with their references. I
    # don't think dollar amounts are going to turn out quite right either:
    #
    # push @nvpair = { name => 'purchase_amount', value => '$230.34' }
    #
    # That might produce an undesired result
    eval {
        if ( $user_defined_var =~ /\$\w*/ || $user_defined_var =~ /{.*}/ || $user_defined_var =~ /\[.*\]/ ) {
            $user_defined_var =~ s/\$/\$Sash::Command::/g;
            eval "\$var = $user_defined_var;";
        } else {
            $var = $user_defined_var;
        }
    }; if ( $@ ) {
        # No reason to die here because undef might be a valid value to the caller.
        return undef;
    }
    
    return $var;
}

# ALL Command Methods

sub all_desc { return <<EOF }
Use this method to get all of the current results in the buffer.
EOF

sub all_doc { return <<EOF }
More to come!
EOF

sub all_proc {
    my $i = 1;
    foreach ( Sash::ResultHistory->all ) {
        print $i++ . ")\n";
        $_->display;
    }

    return;
}

sub x_desc { return <<EOF }
EOF

sub x_doc { return <<EOF }
EOF

sub x_proc {
    my $args = shift;
    
    my $var = __PACKAGE__->_bringVarIntoScope( $args );
    $var = [ $var ] unless ref $var eq 'ARRAY';
    
    $Data::Dumper::Indent = 1;
    $Data::Dumper::Useqq = 1;
    $Data::Dumper::Pair = ' => ';
    
    eval "print Data::Dumper->Dump( \$var, [ qw( $args ) ] );";
    croak $@ if $@;
}

# CLEAR Command Methods.

sub clear_desc { return <<EOF }
EOF

sub clear_doc { return <<EOF }
More to come!
EOF

sub clear_proc {
    # Remember this is a tied variable so explicitly set the contents to null.
    # Undef would not be good here.
    $_buffer = '';
    return;
}

# EDIT BUFFER Command Methods.

sub edit_buffer_desc { return <<EOF }
Use this command to edit the current query buffer.
EOF

sub edit_buffer_doc { return <<EOF }
More to come!
EOF

sub edit_buffer_meth {
    my $term = shift;

    Sash::Command->writing_query( 1 );

    # Thank You Tied Variables!
    system( '$EDITOR ' . Sash::Buffer->filename );
    $_buffer =~ s/\s+$//;
    print $_buffer;

    $term->set_continue_prompt; 

    return;
}

# GREP Command Methods

sub grep_meth {
    my $term = shift;
    ( my $options, my $regex ) = ( my $args = shift->{rawline} ) =~ /grep *-([iv]*) +(.*);$/;

    # Move into Sash::Table like i did with match_string and sort?
    my $data = Sash::ResultHistory->current( )->rowRefs();
    my $grep_result = Sash::Table->new( $data, Sash::ResultHistory->current( )->{header} );
    $grep_result->match_string( $regex );

    Sash::Command->end( { result => $grep_result } );

    return;
}

# HELP Command Methods

sub help_desc { return <<EOF }
Sash Rules!
EOF

sub help_doc { return <<EOF }
More help to come!
EOF

sub help_args {
    shift->help_args( undef, @_ );
}   

sub help_meth {
    shift->help_call( undef, @_ );
}   

# HISTORY Command Methods

sub history_desc { return <<EOF }
Prints the command history"
EOF

sub history_doc { return <<EOF }
usage: history [cd] N

Specify a number to list the last N lines of history.  Pass -c to clear
the command history, -d num to delete a single item.
EOF

sub history_args {
    return "[-c] [-d] [number]";
}

sub history_meth {
    shift->history_call( @_ );
}

# LIMIT Command Methods

sub limit_desc { return <<EOF }
Use this command to reduce the viewable size of the current result set
EOF

sub limit_doc { return <<EOF }
usage: limit n

Reduce the viewable size of the current result to n rows.  Use the revert command
to undo this operation on the result set.
EOF

sub limit_proc {
    ( my $limit = shift ) =~ s/;$//;

    Sash::Command->begin;

    my $data = [ @{Sash::ResultHistory->current( )->rowRefs()}[0 .. $limit - 1] ];
    Sash::Command->end( { result => Sash::Table->new( $data, Sash::ResultHistory->current( )->{header} ) } );

    return;
}

# LIST Command Methods

sub list_desc { return <<EOF }
EOF

sub list_doc { return <<EOF }
More to come!
EOF

sub list_proc {
    print $_buffer if $_buffer;
    return;
}

# QUIT Command Methods

sub quit_desc { return <<EOF }
Quit the application
EOF

sub quit_doc { return <<EOF }
Did you really mean to type help on the quit command?  Really?
EOF

sub quit_meth {
    shift->exit_requested( 1 );
}

# RECONNECT Command Methods

sub reconnect_desc { return <<EOF }
Use this method to reconnect to the datasource
EOF

sub reconnect_doc { return <<EOF }
More to come!
EOF

sub reconnect_proc {
    my $plugin = Sash::Plugin::Factory->get_plugin;

    $plugin->connect( {
        username => $plugin->username,
        password => $plugin->password,
        endpoint => $plugin->endpoint,
    } );

    return;
}

# REDO Command Methods

sub redo_desc { return <<EOF }
Use this method to redo the last result command
EOF

sub redo_doc { return <<EOF }
More to come!
EOF

sub redo_proc {
    # Be explicit for clarity
    my $table = Sash::ResultHistory->redo;
    $table->display;

    return;
}

# REVERT Command Methods

sub revert_desc { return <<EOF }
Use this method to reset the current result set to original size
EOF

sub revert_doc { return <<EOF }
More to come!
EOF

sub revert_proc {
    # Be explicit for clarity
    my $table = Sash::ResultHistory->revert;
    $table->display;

    return;
}

# SEARCH Command Methods

sub search_desc { return <<EOF }
Sash Rules!
EOF

sub search_doc { return <<EOF }
More help to come!
EOF

sub search_proc {
    my $pattern;
    my $args;

    die "usage: result grep [iv] regex\n" if scalar @_ > 2;

    Sash::Command->begin;

    if ( scalar @_ == 1 ) {
        $pattern = shift;
    } else {
        $args = shift;
        $pattern = shift;
    }

    my $ignore_case = 1 if defined $args && $args =~ /i/;

    my $pattern_result = Sash::ResultHistory->current( )->match_string( $pattern, $ignore_case );

    if ( scalar @{$pattern_result->data} > 0 ) {
        if ( defined $args && $args =~ /v/ ) {
            # This is lossy but should be effective for what we need to do.
            my %match_rows = map { ( join '^^^^', @$_ ) => $_ } @{$pattern_result->rowRefs};
            my $data = [ map { if ( $match_rows{ join '^^^^', @$_ } ) { } else { $_ } } @{Sash::ResultHistory->current( )->rowRefs} ];

            Sash::Command->end( { result => Sash::Table->new( $data, Sash::ResultHistory->current( )->{header} ) } );
        } else {
            Sash::Command->end( { result => $pattern_result } );
        }
    } else {
        print "No matches found.\n";
    }

    return;
}

# SET_OUTPUT Command Methods

sub set_output_desc { return <<EOF }
EOF

sub set_output_doc { return <<EOF }
EOF

# Just a wrapper.
sub set_output_proc {
    my $output = lc( shift );
    
    Sash::Properties->output( $output );
}

# SELECT Command Methods

sub select_desc { return <<EOF }
Use this command to select data from an available object
EOF

sub select_doc { return <<EOF }
More to come
Can you dig?
EOF

# This is really just a wrapper to execute_query which is the 
# true Sash::Command that gets executed so no reason to add those
# begin/end invocations here.

sub select_meth {
    my $class = shift;
    my $term = shift;
    my $args = shift;

    $_writing_query = 1;

    # Resetting the buffer won't be valid if query adds union/intersect
    # to the language
    ( $_buffer = $args->{rawline} ) =~ s/;$//;

    if ( $args->{rawline} =~ /;$/ ) {
        $_writing_query = 0;
        Sash::Command->execute_query( $term, $_buffer, $args->{cursor_class} );
    } else {
        $term->set_continue_prompt;
    }
}

sub execute_query {
    my $class = shift;
    my $term = shift;
    my $query = shift;
    my $cursor_class = shift;

    $term->set_standard_prompt;

    Sash::Command->begin;
        
    $_writing_query = 0;
    
    my $table;
    my $data = [ ];
    my $header;
    my $cursor;

    # We will assume that we do not want to get all of the records for
    # really large query result sets.
    my $retrieve_all_records = 0;

    eval {
        $cursor = $cursor_class->open( {
            query => $query,
            caller => 'execute_query'
        } );
    }; if ( $@ ) {
        die $@;
    }

    while ( my $table = $cursor->fetch ) {
        $data = [ @$data, @{$table->rowRefs} ];
        $header = $table->{header} unless defined $header;
        
        $retrieve_all_records = 1 if $cursor->size <= Sash::Command->large_query_size;
        
        $retrieve_all_records = $term->prompt_for( 'retrieve all ' . $cursor->size . ' records? (y/n)' )
            if $cursor->size > Sash::Command->large_query_size && ! $retrieve_all_records;
        
        $retrieve_all_records = 0 if $retrieve_all_records =~ /n/i;
        
        last unless $retrieve_all_records;
    }

    $cursor->close;

    $table = Sash::Table->new( $data, $header );

    # Special case that no records came back from the query.
    if ( scalar @{$table->rowRefs} ) {
        Sash::Command->end( { result => $table } );
    } else {
        Sash::Command->end;
        print 'Empty set ' . Sash::Command->elapsed . "\n";
    }

    return;
}

# SORT Command Methods 

sub sort_desc { return <<EOF }
Use this command to sort the data in the currect result set
EOF

sub sort_doc { return <<EOF }
More to come!
EOF

sub sort_meth {
    my $term = shift;
    ( my $args = shift->{rawline} ) =~ s/sort *(.*?);?/$1/g;
    
    die "You must select a record set first\n" unless Sash::ResultHistory->size > 0;

    Sash::Command->begin;

    my @tokens = split /,/, $args;
    my @sort;
        
    foreach ( @tokens ) {
        my $column;
        my $order;
        my $type;
        my @group;
            
        foreach ( split / / ) {
            if ( /^alpha|num|asc|desc|0|1/ ) {
                $type = 1 if ( $_ eq 'alpha' );
                $type = 0 if ( $_ eq 'num' );
                $order = 1 if ( $_ eq 'desc' );
                $order = 0 if ( $_ eq 'asc' );
            } else {
                $column = $_;
            }
        }
            
        # Examine if we need to provide defaults
        $type = 1 unless defined $type;
        $order = 1 unless defined $order;
            
        push @sort, $column, $type, $order;
    }

    Sash::Command->end( { result => Sash::ResultHistory->current( )->sort( @sort ) } );

    return;
}

# UNDO Command Methods

sub undo_desc { return <<EOF }
Use this method to undo the last result command
EOF

sub undo_doc { return <<EOF }
More to come!
EOF

sub undo_proc {
    # Be explicit for clarity.  ResultHistory gives back an instance of
    # Sash::Table hence the second line.
    my $table = Sash::ResultHistory->undo;
    $table->display;

    return;
}


1;
