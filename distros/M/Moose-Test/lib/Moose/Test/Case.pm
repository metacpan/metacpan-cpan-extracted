package Moose::Test::Case;
use Path::Class ();

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

# Moose boilerplate {{{
sub new {
    my $class = shift;
    my %args  = @_;

    $args{test_dir} ||= do { # default
        require FindBin;
        Path::Class::Dir->new(
            $FindBin::Bin, ($0 =~ /^.*\/(.*?)(?:--.*?)?\.t$/)
        );
    };

    bless \%args, $class;
}

sub test_dir { shift->{test_dir} }

sub pm_files {
    my $self = shift;

    if (!exists($self->{pm_files})) { # lazy
        $self->{pm_files} = [
            sort
            map  { $_->basename }
            grep { -f $_ && /\.pm$/ }
            $self->test_dir->children
        ];
    }

    return $self->{pm_files};
}

sub test_files {
    my $self = shift;

    if (!exists($self->{test_files})) { # lazy
        $self->{test_files} = [
            sort
            map  { $_->basename }
            grep { -f $_ && /\.(pl|t)$/ }
            $self->test_dir->children
        ];
    }

    return $self->{test_files};
}
# }}}

sub load_pm_file {
    my $self    = shift;
    my $pm_file = shift;

    require $pm_file;
}

sub prepare_pm_files {
    my $self = shift;
    my $dir  = $self->test_dir;
    map { $dir->file($_) } @{ $self->pm_files }
}

sub load_pm_files {
    my $self = shift;
    foreach my $pm_file ($self->prepare_pm_files) {
        $self->load_pm_file($pm_file);
    }
}

sub prepare_test_files {
    my $self = shift;
    my $dir  = $self->test_dir;
    map { $dir->file($_) } @{ $self->test_files }
}

sub run_test_file {
    my $self = shift;
    my $file = shift;

    package main;
    eval Path::Class::file($file)->slurp;
    die $@ if $@;
}

sub create_test_body {
    my $self = shift;
    my $dir  = $self->test_dir;
    my $body = '';
    foreach my $file (@{ $self->pm_files }, @{ $self->test_files }) {
        $body .= "\n{\n" . $dir->file($file)->slurp . "\n}\n";
    }
    return $body;
}

sub run_tests {
    my $self = shift;
    my %args = (
        before_first_pm => sub { },
        after_last_pm   => sub { },
        before_pm       => sub { },
        after_pm        => sub { },
        before_first_t  => sub { },
        after_last_t    => sub { },
        before_t        => sub { },
        after_t         => sub { },
        @_,
    );

    $args{before_first_pm}->();
    foreach my $pm_file ($self->prepare_pm_files) {
        $args{before_pm}->($pm_file);
        $self->load_pm_file($pm_file);
        $args{after_pm}->($pm_file);
    }
    $args{after_last_pm}->();

    $args{before_first_t}->();
    for my $file ($self->prepare_test_files) {
        $args{before_t}->($file);
        $self->run_test_file($file);
        $args{after_t}->($file);
    }
    $args{after_last_t}->();
}

1;

__END__

=pod

=head1 NAME

Moose::Test::Case - An abstraction of a Moose Test script

=head1 DESCRIPTION

The meat of the module.

=head1 METHODS

=head2

This method is an abstraction of all the others. You get to run code at certain
hook points, such as "after all classes are loaded", or "before each test script
is run".

The hook points are:

=over 4

=item before_first_pm

=item before_pm

=item after_pm

=item after_last_pm

=item before_first_t

=item before_t

=item after_t

=item after_last_t

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

