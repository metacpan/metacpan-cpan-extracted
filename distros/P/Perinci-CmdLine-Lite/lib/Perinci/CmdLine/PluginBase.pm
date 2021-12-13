package Perinci::CmdLine::PluginBase;

# put pragmas + Log::ger here
use strict 'subs', 'vars';
use warnings;

# put other modules alphabetically here
#require Perinci::CmdLine::Base;

# put global variables alphabetically here
our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-12-11'; # DATE
our $DIST = 'Perinci-CmdLine-Lite'; # DIST
our $VERSION = '1.916'; # VERSION

sub new {
    my ($class, %args) = (shift, @_);
    bless \%args, $class;
}

sub activate {
    my ($self, $wanted_event, $wanted_prio) = @_;

    my $pkg = ref($self);
    my $symtbl = \%{$pkg . "::"};

    (my $plugin_name = $pkg) =~ s/\APerinci::CmdLine::Plugin:://;

    my $meta;
  CHECK_META: {
        defined &{"$pkg\::meta"} or die "$pkg does not define meta()";
        $meta = &{"$pkg\::meta"}();
        my $v = $meta->{v}; $v = 1 unless defined $v;
        if ($v != 1) {
            die "Cannot use $pkg: meta: I only support v=1 ".
                "but the module has v=$v";
        }
    }

    # register in @Plugin_Instances
    {
        no warnings 'once';
        push @Perinci::CmdLine::Base::Plugin_Instances, $self;
    }

    for my $k (keys %$symtbl) {
        my $v = $symtbl->{$k};
        next unless ref $v eq 'CODE' || defined *$v{CODE};
        next unless $k =~ /^(before_|on_|after_)(.+)$/;

        my $meta_method = "meta_$k";
        my $methmeta = $self->can($meta_method) ? $self->$meta_method : {};

        (my $event = $k) =~ s/^on_//;

        $self->cmdline->_plugin_add_handler(
            defined $wanted_event ? $wanted_event : $event,
            $plugin_name,
            (defined $wanted_prio ? $wanted_prio :
             defined $methmeta->{prio} ? $methmeta->{prio} :
             defined $meta->{prio} ? $meta->{prio} : 50),
            sub {
                my $stash = shift;
                $self->$k($stash);
            },
        );
    }
}

sub cmdline {
    $_[0]{cmdline};
}

1;
# ABSTRACT: Base class for Perinci::CmdLine plugin

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::CmdLine::PluginBase - Base class for Perinci::CmdLine plugin

=head1 VERSION

This document describes version 1.916 of Perinci::CmdLine::PluginBase (from Perl distribution Perinci-CmdLine-Lite), released on 2021-12-11.

=head1 DESCRIPTION

This base class allows you to write handlers as methods with names
/^(before_|on_|after_)EVENT_NAME$/ and metadata like priority in the
/^meta_HANDLER/ method.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-CmdLine-Lite>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-CmdLine-Lite>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2019, 2018, 2017, 2016, 2015, 2014 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-CmdLine-Lite>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
