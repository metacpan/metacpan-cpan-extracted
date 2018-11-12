package Pcore::Util::Src::Filter;

use Pcore -role, -res, -const;

has data => ( required => 1 );                          # ScalarRef
has has_kolon => ( is => 'lazy', init_arg => undef );

sub src_cfg ($self) { return Pcore::Util::Src::cfg() }

sub dist_cfg ($self) { return {} }

sub decompress ($self) { return res 200 }

sub compress ($self) { return res 200 }

sub obfuscate ($self) { return res 200 }

sub _build_has_kolon ($self) {
    return 1 if $self->{data}->$* =~ /<: /sm;

    return 1 if $self->{data}->$* =~ /^: /sm;

    return 0;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::Src::Filter

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
