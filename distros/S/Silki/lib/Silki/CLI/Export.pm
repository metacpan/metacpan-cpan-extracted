package Silki::CLI::Export;
{
  $Silki::CLI::Export::VERSION = '0.29';
}

use strict;
use warnings;
use namespace::autoclean;
use autodie;

use Cwd qw( abs_path );
use Path::Class qw( dir );
use Silki::Schema::Process;
use Silki::Schema::Wiki;
use Silki::Types qw( Str );
use Silki::Wiki::Exporter;

use Moose;
use Moose::Util::TypeConstraints;

with qw( MooseX::Getopt::Dashes Silki::Role::CLI::HasOptionalProcess );

{
    subtype 'Wiki', as 'Silki::Schema::Wiki';
    coerce 'Wiki',
        from Str,
        via { Silki::Schema::Wiki->new( short_name => $_ ) };

    MooseX::Getopt::OptionTypeMap->add_option_type_to_map( 'Wiki' => '=s' );

    has wiki => (
        is            => 'ro',
        isa           => 'Wiki',
        required      => 1,
        coerce        => 1,
        documentation => 'The short name of the wiki to export. Required.',
    );
}

has file => (
    is        => 'ro',
    isa       => Str,
    predicate => '_has_file',
    documentation =>
        'The name of the tarball to be created.'
        . ' If not specified, the tarball is created as'
        . ' export-of-<short-name>.tar.gz in the current directory',
);

sub _run {
    my $self = shift;

    my %p = (
        wiki => $self->wiki(),
        log  => $self->_log_coderef(),
    );

    my $tarball = Silki::Wiki::Exporter->new(%p)->tarball();

    my $new_name
        = $self->_has_file()
        ? $self->file()
        : dir( abs_path() )->file( $tarball->basename() );

    rename $tarball => $new_name;

    return $new_name;
}

sub _final_result_string {
    my $self    = shift;
    my $tarball = shift;

    return $tarball;
}

sub _print_success_message {
    my $self    = shift;
    my $tarball = shift;

    print "\n";
    print '  The '
        . $self->wiki()->short_name()
        . ' wiki has been exported at '
        . $tarball;
    print "\n\n";
}

# Intentionally not made immutable, since we only ever make one of these
# objects in a process.

1;
