package Template::Plugin::PodGenerated;
use strict;
use warnings;
use Class::ISA;
use Devel::Peek 'CvGV';
use Devel::Symdump;
use Pod::Generated 'doc';
use Text::Conjunct;
our $VERSION = '0.05';
use base 'Template::Plugin';

sub new {
    my ($class, $context) = @_;
    my $source = $context->stash->get('SOURCE');
    my $package;
    if ($source =~ /
        ^
        package \s*
        (\w+(::(?:\w+))*)
        \s* ;
    /xms
      ) {
        $package = $1;
    } else {
        die "can't parse package from source\n";
    }

    # This will generate documentation via add_doc.
    eval $source;
    die "can't eval source: $@\n" if $@;

    # now that the source has been evaluated, we can look at the package
    # variables.
    my $version;
    {
        no strict 'refs';
        $version = ${"${package}::VERSION"};
    }
    bless {
        _CONTEXT => $context,
        package  => $package,
        version  => $version,
    }, $class;
}
sub package { $_[0]->{package} }
sub version { $_[0]->{version} }

sub format {
    my ($self, %args) = @_;
    my $result = '';
    my $line = my $indent = ' ' x $args{indent};
    for my $word (split /\s+/ => $args{text}) {
        if (length($line) + 1 + length($word) > $args{width}) {
            $result .= "$line\n";
            $line = $indent . $word;
        } else {
            $line .= ' ' if $line =~ /\S/;
            $line .= $word;
        }
    }
    $result .= "$line\n";
    $result;
}

# Heuristic: It's not a method if it has been imported from another package.
# That is, if the glob is aliased to another package. CvGV() tells us that.
sub is_not_method {
    my ($self, $function, $package) = @_;
    my $current = "${package}::${function}";
    no strict 'refs';
    CvGV(*{$current}{CODE}) ne "*$current";
}

sub get_inheritance_data {
    my $self = shift;

    # If several packages define a function, only the lowest class gets
    # mentioned, as it overrides the definition of its superclasses. Seed the
    # lookup hash with the functions defined in the class that is being
    # documented, as we don't want to report those functions from the
    # inheritance.
    my %seen;
    $seen{$_} = 1
      for map { s/^ $self->{package} :://x; $_ }
      Devel::Symdump->new($self->{package})->functions;
    my @result;
    for my $package (Class::ISA::super_path($self->{package})) {
        my @functions;
        for my $function (Devel::Symdump->new($package)->functions) {
            $function =~ s/^ $package :://x;
            next if $seen{$function}++;
            next if $self->is_not_method($function, $package);
            push @functions => $function;
        }
        push @result => $package, [ $self->sub_order(@functions) ];
    }
    wantarray ? @result : \@result;
}

sub write_inheritance {
    my $self = shift;
    no strict 'refs';
    my @inherited = @{ $self->{package} . '::ISA' };
    my $result    = $self->format(
        indent => 0,
        width  => 75,
        text   => sprintf "%s inherits from %s.\n",
        $self->{package},
        conjunct and => map { "L<$_>" } @inherited
    );
    my @inheritance = $self->get_inheritance_data;
    while (my ($package, $functions) = splice(@inheritance, 0, 2)) {
        next unless @$functions;
        $result .= "\n";
        $result .= $self->format(
            indent => 0,
            width  => 75,
            text =>
              "The superclass L<$package> defines these methods and functions:"
        );
        $result .= "\n";
        $result .= $self->format(
            indent => 4,
            width  => 75,
            text   => join ', ' =>

              # map { "L<$_()|$package/$_>" }
              map { "$_()" } @$functions,
        );
    }
    1 while chomp $result;
    $result;
}

sub write_methods {
    my $self        = shift;
    my %doc         = doc();
    my $package_doc = $doc{ $self->{package} }{CODE} || {};
    my $result      = '';
    for my $sub ($self->sub_order(keys %$package_doc)) {
        my $vars = {
            sub     => $sub,
            purpose => (join "\n" => @{ $package_doc->{$sub}{purpose} }),
            example => (
                join "\n" => map { "    $_" } @{ $package_doc->{$sub}{example} }
            ),
        };
        $result .=
          "=item $vars->{sub}\n\n$vars->{example}\n\n$vars->{purpose}\n\n";
    }
    1 while chomp $result;
    $result;
}

# Basically an alphabetic sort, but sort certain sub names first, such as
# 'new' and 'instance'.
sub sub_order {
    my ($self, @names) = @_;
    my %has;
    @has{@names} = ();

    # partition the names into those that should come first, and the rest
    my @first;
    for my $name (qw(new instance)) {
        next unless exists $has{$name};
        delete $has{$name};
        push @first => $name;
    }
    (sort(@first), sort keys %has);
}
1;
__END__

=for test_synopsis
1;
__END__

=head1 NAME

Template::Plugin::PodGenerated - Template plugin to help generate POD

=head1 SYNOPSIS

    {% USE p = PodGenerated %}

    =head1 NAME

    {% p.package %} - Definition of what this module does

    =head1 SYNOPSIS

        {% p.package %}->new;

    =head1 DESCRIPTION

    =head1 METHODS

    =over 4

    {% p.write_methods %}

    =back

    {% p.write_inheritance %}

    {% PROCESS standard_pod_zid %}

    =cut

=head1 DESCRIPTION

This is a plugin for the L<Template> Toolkit that you can use to generate POD
documentation during C<make> time.

To understand the concepts behind this, please read the documentation of
L<Module::Install::Template> and C<Pod::Generated>.

When this plugin is loaded in a template - using C<USE p = PodGenerated>, for
example - it evaluates the template's source code - which it has by magic of
L<Module::Install::Template> - so it gives participating modules a chance to
generate documentation. For example, if your module uses
L<Class::Accessor::Complex>, documentation for the generated accessors will be
generated during this time.

This plugin provides the following methods to be used in templates:

=over 4

=item C<package>

The current package name as parsed from the source code.

=item C<write_inheritance>

Information about which classes the current class inherits from and which
methods it inherits, as far as known. Only those methods in superclasses for
which documentation has also been generated are found through this mechanism.

This might be improved at some point.

=item C<write_methods>

Write the documentation for the methods in the current package that have
documentation defined for it.

=back

=head1 TAGS

If you talk about this module in blogs, on L<delicious.com> or anywhere else,
please use the C<podgenerated> tag.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-pod-generated@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit <http://www.perl.com/CPAN/> to find a CPAN
site near you. Or see L<http://search.cpan.org/dist/Pod-Generated/>.

=head1 AUTHOR

Marcel GrE<uuml>nauer, C<< <marcel@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2009 by Marcel GrE<uuml>nauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

