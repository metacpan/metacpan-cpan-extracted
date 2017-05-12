#!/usr/bin/perl -w

package Sakai::Nakamura::World;

use 5.008008;
use strict;
use warnings;
use Carp;
use Getopt::Long qw(:config bundling);
use Text::CSV;
use Sakai::Nakamura;
use Sakai::Nakamura::Authn;
use Sakai::Nakamura::WorldUtil;

require Exporter;

use base qw(Exporter);

our @EXPORT_OK = ();

our $VERSION = '0.13';

#{{{sub new

sub new {
    my ( $class, $authn, $verbose, $log ) = @_;
    if ( !defined $authn ) { croak 'no authn provided!'; }
    my $response;
    $verbose = ( defined $verbose ? $verbose : 0 );
    my $world = {
        BaseURL  => ${$authn}->{'BaseURL'},
        Authn    => $authn,
        Message  => q{},
        Response => \$response,
        Verbose  => $verbose,
        Log      => $log
    };
    bless $world, $class;
    return $world;
}

#}}}

#{{{sub set_results
sub set_results {
    my ( $world, $message, $response ) = @_;
    $world->{'Message'}  = $message;
    $world->{'Response'} = $response;
    return 1;
}

#}}}

#{{{sub add
sub add {
    my ( $world, $id, $title, $description, $tags, $visibility, $joinability,
        $world_template )
      = @_;
    my $res = Apache::Sling::Request::request(
        \$world,
        Sakai::Nakamura::WorldUtil::add_setup(
            $world->{'BaseURL'},                  $id,
            ${ $world->{'Authn'} }->{'Username'}, $title,
            $description,                         $tags,
            $visibility,                          $joinability,
            $world_template
        )
    );
    my $success = Sakai::Nakamura::WorldUtil::add_eval($res);
    my $message = "World: \"$id\" ";
    $message .= ( $success ? 'added!' : 'was not added!' );
    $world->set_results( "$message", $res );
    return $success;
}

#}}}

#{{{sub add_from_file
sub add_from_file {
    my ( $world, $file, $fork_id, $number_of_forks ) = @_;
    $fork_id         = defined $fork_id         ? $fork_id         : 0;
    $number_of_forks = defined $number_of_forks ? $number_of_forks : 1;
    my $csv               = Text::CSV->new();
    my $count             = 0;
    my $number_of_columns = 0;
    my @column_headings;
    if ( defined $file && open my ($input), '<', $file ) {

        while (<$input>) {
            if ( $count++ == 0 ) {

                # Parse file column headings first to determine field names:
                if ( $csv->parse($_) ) {
                    @column_headings = $csv->fields();

                    # First field must be id:
                    if ( $column_headings[0] !~ /^[Ii][Dd]$/msx ) {
                        croak
'First CSV column must be the world ID, column heading must be "id". Found: "'
                          . $column_headings[0] . "\".\n";
                    }
                    $number_of_columns = @column_headings;
                }
                else {
                    croak 'CSV broken, failed to parse line: '
                      . $csv->error_input;
                }
            }
            elsif ( $fork_id == ( $count++ % $number_of_forks ) ) {
                if ( $csv->parse($_) ) {
                    my @columns      = $csv->fields();
                    my $columns_size = @columns;

           # Check row has same number of columns as there were column headings:
                    if ( $columns_size != $number_of_columns ) {
                        croak
"Found \"$columns_size\" columns. There should have been \"$number_of_columns\".\nRow contents was: $_";
                    }
                    my $id = $columns[0];
                    my $title;
                    my $description;
                    my $tags;
                    my $visibility;
                    my $joinability;
                    my $world_template;

                    for ( my $i = 1 ; $i < $number_of_columns ; $i++ ) {
                        my $heading = $column_headings[$i];
                        if ( $heading =~ /^[Tt][Ii][Tt][Ll][Ee]$/msx ) {
                            $title = $columns[$i];
                        }
                        elsif ( $heading =~
                            /^[Dd][Ee][Ss][Cc][Rr][Ii][Pp][Tt][Ii][Oo][Nn]$/msx
                          )
                        {
                            $description = $columns[$i];
                        }
                        elsif ( $heading =~ /^[Tt][Aa][Gg][Ss]$/msx ) {
                            $tags = $columns[$i];
                        }
                        elsif ( $heading =~
                            /^[Vv][Ii][Ss][Ii][Bb][Ii][Ll][Ii][Tt][Yy]$/msx )
                        {
                            $visibility = $columns[$i];
                        }
                        elsif ( $heading =~
                            /^[Jj][Oo][Ii][Nn][Aa][Bb][Ii][Ll][Ii][Tt][Yy]$/msx
                          )
                        {
                            $joinability = $columns[$i];
                        }
                        elsif ( $heading =~
/^[Ww][Oo][Rr][Ll][Dd][Tt][Ee][Mm][Pp][Ll][Aa][Tt][Ee]$/msx
                          )
                        {
                            $world_template = $columns[$i];
                        }
                        else {
                            croak
"Unsupported column heading \"$heading\" - please use: \"id\", \"title\", \"description\", \"tags\", \"visibility\", \"joinability\", \"worldtemplate\"";
                        }
                    }
                    $world->add( $id, $title, $description, $tags, $visibility,
                        $joinability, $world_template );
                    Apache::Sling::Print::print_result($world);
                }
                else {
                    croak q{CSV broken, failed to parse line: }
                      . $csv->error_input;
                }
            }
        }
        close $input or croak q{Problem closing input};
    }
    else {
        croak 'Problem adding from file!';
    }
    return 1;
}

#}}}

#{{{ sub command_line
sub command_line {
    my ( $class, @ARGV ) = @_;
    my $nakamura = Sakai::Nakamura->new;
    my $config   = $class->config( $nakamura, @ARGV );
    my $authn    = new Sakai::Nakamura::Authn( \$nakamura );
    return $class->run( $nakamura, $config );
}

#}}}

#{{{sub config

sub config {
    my ( $class, $nakamura, @ARGV ) = @_;
    my $world_config = $class->config_hash( $nakamura, @ARGV );

    GetOptions(
        $world_config,        'auth=s',
        'help|?',             'log|L=s',
        'man|M',              'pass|p=s',
        'threads|t=s',        'url|U=s',
        'user|u=s',           'verbose|v+',
        'add|a',              'additions|A=s',
        'copy|c',             'delete|d',
        'exists|e',           'filename|n=s',
        'local|l=s',          'move|m',
        'property|P=s',       'remote|r=s',
        'remote-source|S=s',  'replace|R',
        'view|V',             'view-copyright=s',
        'view-description=s', 'view-tags=s',
        'view-title=s',       'view-visibility=s'
    ) or $class->help();

    return $world_config;
}

#}}}

#{{{sub config_hash

sub config_hash {
    my ( $class, $nakamura, @ARGV ) = @_;
    my $add;
    my $additions;
    my $id;
    my $title;
    my $description;
    my $tags;
    my $visibility;
    my $joinability;
    my $world_template;
    my %world_config = (
        'auth'           => \$nakamura->{'Auth'},
        'help'           => \$nakamura->{'Help'},
        'log'            => \$nakamura->{'Log'},
        'man'            => \$nakamura->{'Man'},
        'pass'           => \$nakamura->{'Pass'},
        'threads'        => \$nakamura->{'Threads'},
        'url'            => \$nakamura->{'URL'},
        'user'           => \$nakamura->{'User'},
        'verbose'        => \$nakamura->{'Verbose'},
        'add'            => \$add,
        'additions'      => \$additions,
        'title'          => \$title,
        'description'    => \$description,
        'tags'           => \$tags,
        'visibility'     => \$visibility,
        'joinability'    => \$joinability,
        'world_template' => \$world_template
    );

    return \%world_config;
}

#}}}

#{{{ sub help
sub help {

    print <<"EOF";
Usage: perl $0 [-OPTIONS [-MORE_OPTIONS]] [--] [PROGRAM_ARG1 ...]
The following options are accepted:

 --add or -a (worldid)               - add specified world.
 --additions or -A (file)            - file containing list of worlds to be added.
 --auth (type)                       - Specify auth type. If ommitted, default is used.
 --description or -d                 - description of world
 --help or -?                        - view the script synopsis and options.
 --joinability or -j (joinability)   - Joinability of world.
 --log or -L (log)                   - Log script output to specified log file.
 --man or -M                         - view the full script documentation.
 --pass or -p (password)             - Password of user performing actions.
 --threads or -t (threads)           - Used with -A, defines number of parallel
                                       processes to have running through file.
 --tags or -T (tags)                 - tags for world
 --title or -t (title)               - title for world
 --url or -U (URL)                   - URL for system being tested against.
 --user or -u (username)             - Name of user to perform any actions as.
 --verbose or -v or -vv or -vvv      - Increase verbosity of output.
 --visibility or -V (visibility)     - Visibility of world.
 --worldTemplate or -w               - World template to use.

Options may be merged together. -- stops processing of options.
Space is not required between options and their arguments.
For full details run: perl $0 --man
EOF

    return 1;
}

#}}}

#{{{ sub man
sub man {
    my ($world) = @_;

    print <<'EOF';
world perl script. Provides a means of managing worlds in nakamura from the command
line. The script also acts as a reference implementation for the World perl
library.

EOF

    $world->help();

    print <<"EOF";
Example Usage

* TODO: add examples

 perl $0 -U http://localhost:8080 -u admin -p admin
EOF

    return 1;
}

#}}}

#{{{sub run
sub run {
    my ( $world, $nakamura, $config ) = @_;
    if ( !defined $config ) {
        croak 'No world config supplied!';
    }
    $nakamura->check_forks;
    my $authn =
      defined $nakamura->{'Authn'}
      ? ${ $nakamura->{'Authn'} }
      : new Sakai::Nakamura::Authn( \$nakamura );

    my $success = 1;

    if    ( $nakamura->{'Help'} ) { $world->help(); }
    elsif ( $nakamura->{'Man'} )  { $world->man(); }
    elsif ( defined ${ $config->{'additions'} } ) {
        my $message =
          "Adding worlds from file \"" . ${ $config->{'additions'} } . "\":\n";
        Apache::Sling::Print::print_with_lock( "$message", $nakamura->{'Log'} );
        my @childs = ();
        for my $i ( 0 .. $nakamura->{'Threads'} ) {
            my $pid = fork;
            if ($pid) { push @childs, $pid; }    # parent
            elsif ( $pid == 0 ) {                # child
                    # Create a new separate user agent per fork in order to
                    # ensure cookie stores are separate, then log the user in:
                $authn->{'LWP'} = $authn->user_agent( $nakamura->{'Referer'} );
                $authn->login_user();
                my $world =
                  new Sakai::Nakamura::World( \$authn, $nakamura->{'Verbose'},
                    $nakamura->{'Log'} );
                $world->add_from_file( ${ $config->{'additions'} },
                    $i, $nakamura->{'Threads'} );
                exit 0;
            }
            else {
                croak "Could not fork $i!";
            }
        }
        foreach (@childs) { waitpid $_, 0; }
    }
    else {
        $authn->login_user();
        if ( defined ${ $config->{'add'} } ) {
            $world =
              new Sakai::Nakamura::World( \$authn, $nakamura->{'Verbose'},
                $nakamura->{'Log'} );
            $success = $world->add(
                ${ $config->{'add'} },
                ${ $config->{'title'} },
                ${ $config->{'description'} },
                ${ $config->{'tags'} },
                ${ $config->{'visibility'} },
                ${ $config->{'joinability'} },
                ${ $config->{'world_template'} }
            );
            Apache::Sling::Print::print_result($world);
        }
        else {
            $world->help();
            return 1;
        }
    }
    return $success;
}

#}}}

1;

__END__

=head1 NAME

Sakai::Nakamura::World - Manipulate Worlds in a Sakai Nakamura instance.

=head1 ABSTRACT

world related functionality for Sling implemented over rest APIs.

=head1 METHODS

=head2 new

Create, set up, and return a World Object.

=head2 set_results

Update the world object with the message and respsonse from the last method call.

=head2 add

Add a new world to the Sakai Nakamura System.

=head2 add_from_file

Add new worlds to the Sakai Nakamura System, based on entries in a specified file.

=head1 USAGE

use Sakai::Nakamura::World;

=head1 DESCRIPTION

Perl library providing a layer of abstraction to the REST world methods

=head1 REQUIRED ARGUMENTS

None required.

=head1 OPTIONS

n/a

=head1 DIAGNOSTICS

n/a

=head1 EXIT STATUS

0 on success.

=head1 CONFIGURATION

None required.

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

None known.

=head1 BUGS AND LIMITATIONS

None known.

=head1 AUTHOR

Daniel David Parry <perl@ddp.me.uk>

=head1 LICENSE AND COPYRIGHT

LICENSE: http://dev.perl.org/licenses/artistic.html

COPYRIGHT: (c) 2012 Daniel David Parry <perl@ddp.me.uk>
