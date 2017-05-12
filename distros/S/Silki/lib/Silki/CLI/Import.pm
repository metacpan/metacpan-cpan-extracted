package Silki::CLI::Import;
{
  $Silki::CLI::Import::VERSION = '0.29';
}

use strict;
use warnings;
use namespace::autoclean;
use autodie;

use Silki::Schema::Domain;
use Silki::Types qw( Bool Str );
use Silki::Wiki::Importer;

use Moose;

with qw( MooseX::Getopt::Dashes Silki::Role::CLI::HasOptionalProcess );

has tarball => (
    is            => 'ro',
    isa           => Str,
    required      => 1,
    documentation => 'The tarball containing the wiki to import. Required.',
);

has domain => (
    is  => 'ro',
    isa => Str,
    documentation =>
        'The domain for the new wiki. Defaults to the default domain for the site.',
);

has fast => (
    is  => 'ro',
    isa => Bool,
    documentation =>
        'If this is true, the importer will disable triggers during the import.'
        . ' This is not safe if users are using the web interface at the same time,'
        . ' so it defaults to false.'
);

sub _run {
    my $self = shift;

    $self->_replace_dbi_manager() if $self->process();

    my $wiki;

    my %p = (
        tarball => $self->tarball(),
        log     => $self->_log_coderef(),
        fast    => $self->fast(),
    );

    $p{domain} = Silki::Schema::Domain->new( web_hostname => $self->domain() )
        if $self->domain();

    return Silki::Wiki::Importer->new(%p)->imported_wiki();
}

sub _final_result_string {
    my $self = shift;
    my $wiki = shift;

    return $wiki->uri();
}

sub _print_success_message {
    my $self = shift;
    my $wiki = shift;

    print "\n";
    print '  The ' . $wiki->short_name() . ' wiki has been imported.';
    print "\n";
    print '  You can visit it at ' . $wiki->uri( with_host => 1 );
    print "\n\n";
}

# This is a hack to make sure that updatess to the process table are not done
# inside the import transaction. Otherwise the status cannot actually be seen
# until the transaction finishes.
sub _replace_dbi_manager {
    my $self = shift;

    my $new_source = Silki::Schema->DBIManager()->default_source()
        ->clone( name => 'for Process updates' );

    my $man = _DBIManager->new();
    $man->add_source( Silki::Schema->DBIManager()->default_source() );
    $man->add_source($new_source);

    Silki::Schema->SetDBIManager($man);

    return;
}

{

    package _DBIManager;
{
  $_DBIManager::VERSION = '0.29';
}

    use Moose;

    extends 'Fey::DBIManager';

    override source_for_sql => sub {
        my $self = shift;
        my $sql  = shift;

        return $sql->isa('Fey::SQL::Update')
            && $sql->sql('Fey::FakeDBI') =~ /UPDATE "Process"/
            ? $self->get_source('for Process updates')
            : $self->get_source('default');
    };
}

# Intentionally not made immutable, since we only ever make one of these
# objects in a process.

1;
