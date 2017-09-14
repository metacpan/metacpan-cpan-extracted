package Net::WHMCS::Miscellaneous;
$Net::WHMCS::Miscellaneous::VERSION = '0.09';
# ABSTRACT: WHMCS API Miscellaneous

use Moo;
with 'Net::WHMCS::Base';

use Carp 'croak';

sub addproduct {
    my ($self, $params) = @_;
    $params->{action} = 'AddProduct';
    foreach my $r (qw/gid name/) {
        croak "$r is required." unless $params->{$r};
    }
    return $self->build_request($params);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::WHMCS::Miscellaneous - WHMCS API Miscellaneous

=head1 VERSION

version 0.09

=head2 addproduct

	$whmcs->misc->addproduct({
		type => 'other',
		gid => 1,
		name => 'Sample Product',
		paytype => 'recurring',
		'pricing[1][monthly]' => '5.00',
		'pricing[1][annually]' => '50.00',
		...
	});

L<https://developers.whmcs.com/api-reference/addproduct/>

=head1 AUTHOR

Fayland Lam <fayland@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Fayland Lam.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
