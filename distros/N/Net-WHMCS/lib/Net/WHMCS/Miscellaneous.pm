package Net::WHMCS::Miscellaneous;
$Net::WHMCS::Miscellaneous::VERSION = '0.08';

# ABSTRACT: WHMCS API Miscellaneous

use Moo;
with 'Net::WHMCS::Base';

use Carp 'croak';

sub addproduct {
    my ( $self, $params ) = @_;
    $params->{action} = 'addproduct';
    foreach my $r (qw/type gid name paytype/) {
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

version 0.08

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

L<http://docs.whmcs.com/API:Add_Product>

=head1 AUTHOR

Fayland Lam <fayland@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Fayland Lam.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
