package Pod::ProjectDocs;

use strict;
use warnings;

our $VERSION = '0.50';    # VERSION

use Moose;

use File::Spec;
use JSON;
use Pod::ProjectDocs::DocManager;
use Pod::ProjectDocs::Config;
use Pod::ProjectDocs::Parser;
use Pod::ProjectDocs::CSS;
use Pod::ProjectDocs::IndexPage;

has 'managers' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
);
has 'components' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
);
has 'config' => (
    is  => 'ro',
    isa => 'Object',
);

sub BUILDARGS {
    my ( $class, %args ) = @_;

    $args{title} ||= "MyProject's Libraries";
    $args{desc}  ||= "manuals and libraries";
    $args{lang}  ||= "en";

    # set absolute path to 'outroot'
    $args{outroot} ||= File::Spec->curdir;
    $args{outroot} = File::Spec->rel2abs( $args{outroot}, File::Spec->curdir )
      unless File::Spec->file_name_is_absolute( $args{outroot} );

    # set absolute path to 'libroot'
    $args{libroot} ||= File::Spec->curdir;
    $args{libroot} = [ $args{libroot} ] unless ref $args{libroot};
    $args{libroot} = [
        map {
            File::Spec->file_name_is_absolute($_)
              ? $_
              : File::Spec->rel2abs( $_, File::Spec->curdir )
        } @{ $args{libroot} }
    ];

    # check mtime by default, but can be overridden
    $args{forcegen} ||= 0;

    $args{nosourcecode} = 0 if !defined $args{nosourcecode};

    $args{except} ||= [];
    $args{except} = [ $args{except} ] unless ref $args{except};

    $args{config} = Pod::ProjectDocs::Config->new(%args);

    return \%args;
}

sub BUILD {
    my $self = shift;

    $self->components->{css} =
      Pod::ProjectDocs::CSS->new( config => $self->config );
    $self->add_manager( 'Perl Manuals', 'pod', Pod::ProjectDocs::Parser->new );
    $self->add_manager( 'Perl Modules', 'pm',  Pod::ProjectDocs::Parser->new );
    $self->add_manager(
        'Trigger Scripts',
        [ 'cgi', 'pl' ],
        Pod::ProjectDocs::Parser->new
    );

    return;
}

sub add_manager {
    my ( $self, $desc, $suffix, $parser ) = @_;
    push @{ $self->managers },
      Pod::ProjectDocs::DocManager->new(
        config => $self->config,
        desc   => $desc,
        suffix => $suffix,
        parser => $parser,
      );
    return;
}

sub gen {
    my $self = shift;

    foreach my $comp_key ( keys %{ $self->components } ) {
        my $comp = $self->components->{$comp_key};
        $comp->publish();
    }

    my %local_modules;

    foreach my $manager ( @{ $self->managers } ) {
        next if $manager->desc !~ /Perl Modules/;
        for my $doc ( @{ $manager->docs() || [] } ) {
            my $name = $doc->name;
            my $path = $doc->get_output_path;
            if ( $manager->desc eq 'Perl Modules' ) {
                $local_modules{$name} = $path;
            }
        }
    }

    foreach my $manager ( @{ $self->managers } ) {

        $manager->parser->local_modules( \%local_modules );

        for my $doc ( @{ $manager->docs() || [] } ) {
            my $html = $manager->parser->gen_html(
                doc        => $doc,
                desc       => $manager->desc,
                components => $self->components,
            );

            if ( $self->config->forcegen || $doc->is_modified ) {
                if ( !$self->config->nosourcecode ) {
                    $doc->copy_src();
                }
                $doc->publish($html);
            }
        }
    }

    my $index_page = Pod::ProjectDocs::IndexPage->new(
        config     => $self->config,
        components => $self->components,
        json       => $self->get_managers_json,
    );
    $index_page->publish();
    return;
}

sub get_managers_json {
    my $self    = shift;
    my $js      = JSON->new;
    my $records = [];
    foreach my $manager ( @{ $self->managers } ) {
        my $record = {
            desc    => $manager->desc,
            records => [],
        };
        foreach my $doc ( @{ $manager->docs } ) {
            push @{ $record->{records} },
              {
                path  => $doc->relpath,
                name  => $doc->name,
                title => $doc->title,
              };
        }
        if ( scalar( @{ $record->{records} } ) > 0 ) {
            push @$records, $record;
        }
    }

    # Use "canonical" to generate stable structures that can be added
    #   to version control systems without changing all the time.
    return $js->canonical()->encode($records);
}

sub _croak {
    my ( $self, $msg ) = @_;
    require Carp;
    Carp::croak($msg);
    return;
}

1;
__END__

=encoding utf-8

=head1 NAME

Pod::ProjectDocs - generates CPAN like project documents from pod.

=head1 SYNOPSIS

    #!/usr/bin/perl

    use strict;
    use warnings;

    use Pod::ProjectDocs;

    my $pd = Pod::ProjectDocs->new(
        libroot => '/your/project/lib/root',
        outroot => '/output/directory',
        title   => 'ProjectName',
    );
    $pd->gen();

    # or use pod2projdocs on your shell
    pod2projdocs -out /output/directory -lib /your/project/lib/root

=head1 DESCRIPTION

This module allows you to generates CPAN like pod pages from your modules
for your projects. It also creates an optional index page.

=head1 OPTIONS

=over 4

=item C<outroot>

output directory for the generated documentation.

=item C<libroot>

your library's (source code) root directory.

You can set single path by string, or multiple by arrayref.

    my $pd = Pod::ProjectDocs->new(
        outroot => '/path/to/output/directory',
        libroot => '/path/to/lib'
    );

or

    my $pd = Pod::ProjectDocs->new(
        outroot => '/path/to/output/directory',
        libroot => ['/path/to/lib1', '/path/to/lib2'],
    );

=item C<title>

your project's name.

=item C<desc>

description for your project.

=item C<index>

whether you want to create an index for all generated pages (0 or 1).

=item C<lang>

set this language as xml:lang (default 'en')

=item C<forcegen>

whether you want to generate HTML document even if source files are not updated (default is 0).

=item C<nosourcecode>

whether to suppress inclusion of the original source code in the generated output (default is 0).

=item C<except>

the files matches this regex won't be parsed.

  Pod::ProjectDocs->new(
    except => qr/^specific_dir\//,
    ...other parameters
  );

  Pod::ProjectDocs->new(
    except => [qr/^specific_dir1\//, qr/^specific_dir2\//],
    ...other parameters
  );

=back

=head1 pod2projdocs

You can use the command line script L<pod2projdocs> to generate your documentation
without creating a custom perl script.

    pod2projdocs -help

=head1 SEE ALSO

L<Pod::Simple::XHTML>

=head1 AUTHORS

=over 4

=item Lyo Kato E<lt>lyo.kato@gmail.comE<gt>

=item L<Martin Gruner|https://github.com/mgruner> (current maintainer)

=back

=head1 COPYRIGHT AND LICENSE

=over 4

=item © 2005 by Lyo Kato

=item © 2018 by Martin Gruner

=back

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
