
# ##################################
# Here starts the XBase::cdx package

package XBase::cdx;

use strict;
use XBase::Base;


use vars qw( $VERSION @ISA );
@ISA = qw( XBase::Base );


$VERSION = "0.03";

sub read_header
	{
	my $self = shift;

	my $header;
	$self->{'fh'}->read($header, 512) == 512 or do
		{ Error "Error reading header of $self->{'filename'}\n";
		return; };

	my ($root_page1, $root_page2, $free_list, $total_no_pages,
		$key_len, $index_opts, $index_sign, $reserved1,
		$sort_order, $total_exp_len, $for_exp_len,
		$reserved2, $key_exp_len)
			= unpack "nnNNvCCA486vvvvv", $header;

	my $root_page = $root_page1 | ($root_page2 << 16);

	@{$self}{ qw( root_page free_list total_no_pages key_len index_opts
		index_sign sort_order total_exp_len for_exp_len
		key_exp_len ) }
			= ($root_page, $free_list, $total_no_pages, $key_len,
			$index_opts, $index_sign, $sort_order,
			$total_exp_len, $for_exp_len, $key_exp_len);

	1;
	}

sub dump_records
	{
	my $self = shift;

	}

1;

