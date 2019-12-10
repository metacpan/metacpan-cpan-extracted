package Pcore::Util::File::ChdirGuard;

use Pcore -class;

has dir => ( required => 1 );    # Str

sub DESTROY ( $self ) {
    chdir $self->{dir} or die;

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::File::ChdirGuard

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
