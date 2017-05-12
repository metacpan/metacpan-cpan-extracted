package POEIKC::Plugin::GlobalQueue::Message;

use strict;
use 5.008_001;
our $VERSION = '0.01';
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw/createTime expireTime substance tag gqId/);


sub new {
	my $class = shift ;
	my $substance = shift;
	my %hash = @_;
	my $self = $class->SUPER::new();
	$self->createTime(time);
	$self->tag('non-tag');
	$self->substance($substance);
	$self->$_($hash{$_}) for (keys %hash);
	return $self ;
}

sub expire {
	my $self = shift;
	return $self	if not($self->expireTime) or
		($self->createTime  > (time - $self->expireTime));
	return ;
}



1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

POEIKC::Plugin::GlobalQueue::Message - The container of data

=head1 SYNOPSIS

	use POEIKC::Plugin::GlobalQueue::Message;

	my $message = POEIKC::Plugin::GlobalQueue::Message->new(
		{
			AAA=>'aaa',
			BBB=>'bbb',
		},
		tag=>'tagName',
		expireTime=>60, # second
	);




=head1 AUTHOR

Yuji Suzuki E<lt>yujisuzuki@mail.arbolbell.jpE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<poeikcd>
L<POEIKC::Plugin::GlobalQueue
L<POEIKC::Plugin::GlobalQueue::ClientLite>

=cut
