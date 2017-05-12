package Shell::Amazon::S3::Plugin::Colors;

use Moose::Role;
use Term::ANSIColor;
use namespace::clean -except => ['meta'];

has normal_color => (
    is      => 'rw',
    lazy    => 1,
    default => 'green',
);

has error_color => (
    is      => 'rw',
    lazy    => 1,
    default => 'bold red',
);

around error_return => sub {
    my $orig = shift;
    my $self = shift;
    return
          color( $self->error_color )
        . $orig->( $self, @_ )
        . color('reset');
};

# we can't just munge @_ because that screws up DDS
around print => sub {
    my $orig = shift;
    my $self = shift;
    print { $self->out_fh } color( $self->normal_color );
    $orig->( $self, @_ );
    print { $self->out_fh } color('reset');
};

1;

__END__

=head1 NAME

Shell::Amazon::S3::Plugin::Colors - add color to return values, warnings, and errors

=head1 SYNOPSIS

    #!/usr/bin/perl 

    use lib './lib';
    use Shell::Amazon::S3;

    my $repl = Shell::Amazon::S3->new;
    $repl->load_plugin('History');
    $repl->load_plugin('Colors');
    $repl->run;

=head1 DESCRIPTION


=head1 SEE ALSO

C<Shell::Amazon::S3>

=head1 AUTHOR

Dann C<< <techmemo at gmail dot com> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Dann

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
