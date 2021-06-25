package Perinci::CmdLine::PluginBase;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-06-23'; # DATE
our $DIST = 'Perinci-CmdLine-Lite'; # DIST
our $VERSION = '1.905'; # VERSION

# IFUNBUILT
# use strict 'subs', 'vars';
# use warnings;
# END IFUNBUILT

#require Perinci::CmdLine::Base;

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
        my $meta = $self->can($meta_method) ? $self->$meta_method : {};

        (my $event = $k) =~ s/^on_//;

        Perinci::CmdLine::Base::__plugin_add_handler(
            defined $wanted_event ? $wanted_event : $event,
            $plugin_name,
            defined $wanted_prio ? $wanted_prio :
                (defined $meta->{prio} ? $meta->{prio} : 50),
            sub {
                my $stash = shift;
                $self->$k($stash);
            },
        );
    }
}

1;
# ABSTRACT: Base class for Perinci::CmdLine plugin

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::CmdLine::PluginBase - Base class for Perinci::CmdLine plugin

=head1 VERSION

This document describes version 1.905 of Perinci::CmdLine::PluginBase (from Perl distribution Perinci-CmdLine-Lite), released on 2021-06-23.

=head1 DESCRIPTION

This base class allows you to write handlers as methods with names
/^(before_|on_|after_)EVENT_NAME$/ and metadata like priority in the
/^meta_HANDLER/ method.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-CmdLine-Lite>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-CmdLine-Lite>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Perinci-CmdLine-Lite/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2019, 2018, 2017, 2016, 2015, 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
