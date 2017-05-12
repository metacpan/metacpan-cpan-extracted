package Resource::Pack;
BEGIN {
  $Resource::Pack::VERSION = '0.03';
}
use Moose::Exporter;
# ABSTRACT: tools for managing application resources

use Bread::Board;
use Carp qw(confess);
use Scalar::Util qw(blessed);

use Resource::Pack::Dir;
use Resource::Pack::File;
use Resource::Pack::Resource;
use Resource::Pack::URL;



our $CC;


sub resource ($;$$) {
    my $name = shift;
    my $c;
    my $name_is_resource = blessed($name)
                        && $name->isa('Resource::Pack::Resource');
    if (@_ == 0) {
        return $name if $name_is_resource;
        return Resource::Pack::Resource->new(name => $name);
    }
    elsif (@_ == 1) {
        $c = $name_is_resource
            ? $name
            : Resource::Pack::Resource->new(name => $name);
    }
    else {
        confess "Parameterized resources are not currently supported";
    }
    my $body = shift;
    if (defined $CC) {
        $CC->add_sub_container($c);
    }
    if (defined $body) {
        local $_  = $c;
        local $CC = $c;
        $body->($c);
    }
    return $c;
}


sub file ($@) {
    my $name = shift;
    unshift @_, 'file' if @_ % 2 == 1;
    $CC->add_file(@_, name => $name);
}


sub dir ($@) {
    my $name = shift;
    unshift @_, 'dir' if @_ % 2 == 1;
    $CC->add_dir(@_, name => $name);
}


sub url ($@) {
    my $name = shift;
    unshift @_, 'url' if @_ % 2 == 1;
    $CC->add_url(@_, name => $name);
}


sub install_to ($) {
    $CC->install_to_dir(shift);
}


sub install_from ($) {
    $CC->install_from_dir(shift);
}


sub install_as ($) {
    $CC->install_as(shift);
}

{
    no warnings 'redefine';
    sub include ($) {
        my $file = shift;
        my $resources = Path::Class::File->new($file)->slurp . ";\n1;";
        if (!eval $resources) {
            die "Couldn't compile $file: $@" if $@;
            die "Unknown error when compiling $file";
        }
    }
}

Moose::Exporter->setup_import_methods(
    also  => ['Bread::Board'],
    as_is => [qw(resource file dir url install_to install_from install_as
                 include)],
);


1;

__END__
=pod

=head1 NAME

Resource::Pack - tools for managing application resources

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    my $resources = resource my_app => as {
        install_from 'data';
        install_to   '/var/www/site';

        url jquery => 'http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js';
        file app_js => 'app.js';
        file app_css => (
            file       => 'app.css',
            install_to => 'css',
        );
        dir 'images';
    };

    $resources->install;

or, to package this up nicely in a class:

    package My::App::Resources;
    use Moose;
    use Resource::Pack;

    extends 'Resource::Pack::Resource';

    has '+name' => (default => 'my_app');

    sub BUILD {
        my $self = shift;

        resource $self => as {
            install_from 'data';

            url jquery => 'http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js';
            file app_js => 'app.js';
            file app_css => (
                file       => 'app.css',
                install_to => 'css',
            );
            dir 'images';
        };
    }

    my $resources = My::App::Resources->new(install_to => '/var/www/site');
    $resources->install;

=head1 DESCRIPTION

Resource::Pack is a set of L<Moose> classes, built on top of L<Bread::Board>,
designed to allow managing non-Perl resources in a very CPAN friendly way.

In the past if you wanted to distribute your non-Perl code via CPAN there were
a number of less then ideal ways to do it. The simplest was to store the data
in Perl strings or encoded as binary data; this is ugly to say the least. You
could also use a module like L<File::ShareDir>, which relies on the fact that
CPAN can be told to install files inside a directory called C<share>. This
technique is both reliable and comes with a decent set of tools to make
accessing these files pretty simple and easy. And lastly there are tools like
L<JS>, which installs C<js-cpan>, and exploits the fact that CPAN will also
install non-Perl files it finds inside C<lib> alongside your regular Perl
files.

So, what does Resource::Pack provide beyond these tools? Mostly it provides a
framework which you can use to inspect and manipulate these non-Perl files, and
most importantly it provides dependency management. Resource::Pack also can
depend on files out on the internet as well and deal with them in the same way
as it does local files.

So, this is all the docs I have for now, but more will come soon. This is an
early release of this module so it should still be considered experimental and
so used with caution. As always the best docs are probably the test files.

=head1 EXPORTS

Resource::Pack exports everything that L<Bread::Board> exports, as well as:

=head2 resource NAME BODY

Defines a new L<Resource::Pack::Resource> with name NAME, and runs BODY to
populate it. This works similarly to C<container> in L<Bread::Board>, except
that it doesn't currently support parameters.

=head2 file NAME PARAMS

Defines a L<Resource::Pack::File> object in the current resource, with the name
NAME. PARAMS are passed to the Resource::Pack::File constructor, with a default
parameter of C<file> if only one argument is passed.

=head2 dir NAME PARAMS

Defines a L<Resource::Pack::Dir> object in the current resource, with the name
NAME. PARAMS are passed to the Resource::Pack::Dir constructor, with a default
parameter of C<dir> if only one argument is passed.

=head2 url

Defines a L<Resource::Pack::URL> object in the current resource, with the name
NAME. PARAMS are passed to the Resource::Pack::URL constructor, with a default
parameter of C<url> if only one argument is passed.

=head2 install_to PATH

Sets the C<install_to> option for the current resource.

=head2 install_from PATH

Sets the C<install_from> option for the current resource.

=head2 install_as PATH

Sets the C<install_as> option for the current resource.

=head1 TODO

=over 4

=item Support for archive/zip files

It would be nice to be able to store a set of files inside an archive of some
kind, and make it just as simple to inspect and unzip that archive. It would
also be nice to allow downloading of zip files from the net.

=item Symlink support

Currently L<Resource::Pack::Installable> only supports copying files and
directories. It would be nice to also support symlinking to the original files
stored in the Perl @INC directories.

=back

=head1 BUGS/CAVEATS

No known bugs.

Please report any bugs through RT: email
C<bug-resource-pack at rt.cpan.org>, or browse to
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Resource-Pack>.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<JS>

=item *

L<File::ShareDir>

=item *

L<Bread::Board>

=back

=head1 SUPPORT

You can find this documentation for this module with the perldoc command.

    perldoc Resource::Pack

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Resource-Pack>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Resource-Pack>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Resource-Pack>

=item * Search CPAN

L<http://search.cpan.org/dist/Resource-Pack>

=back

=head1 AUTHORS

=over 4

=item *

Stevan Little <stevan.little@iinteractive.com>

=item *

Jesse Luehrs <doy at tozt dot net>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

