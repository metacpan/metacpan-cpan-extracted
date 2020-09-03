package ScriptX::Base;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-09-03'; # DATE
our $DIST = 'ScriptX'; # DIST
our $VERSION = '0.000001'; # VERSION

# IFUNBUILT
# use strict 'subs', 'vars';
# use warnings;
# END IFUNBUILT

require ScriptX;

sub new {
    my ($class, %args) = (shift, @_);
    bless \%args, $class;
}

sub activate {
    my ($self, $wanted_event, $wanted_prio) = @_;

    my $pkg = ref($self);
    my $symtbl = \%{$pkg . "::"};

    (my $plugin_name = $pkg) =~ s/\AScriptX:://;

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

    # register in %Plugins
    $ScriptX::Plugins{$plugin_name} = $self;

    for my $k (keys %$symtbl) {
        my $v = $symtbl->{$k};
        next unless ref $v eq 'CODE' || defined *$v{CODE};
        next unless $k =~ /^(before_|on_|after_)(.+)$/;

        my $meta_method = "meta_$k";
        my $meta = $self->can($meta_method) ? $self->$meta_method : {};

        (my $event = $k) =~ s/^on_//;

        ScriptX::add_handler(
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
# ABSTRACT: Base class for ScriptX plugin

__END__

=pod

=encoding UTF-8

=head1 NAME

ScriptX::Base - Base class for ScriptX plugin

=head1 VERSION

This document describes version 0.000001 of ScriptX::Base (from Perl distribution ScriptX), released on 2020-09-03.

=head1 DESCRIPTION

This base class allows you to write handlers as methods with names
/^(before_|on_|after_)EVENT_NAME$/ and metadata like priority in the
/^meta_HANDLER/ method.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/ScriptX>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-ScriptX>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=ScriptX>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
