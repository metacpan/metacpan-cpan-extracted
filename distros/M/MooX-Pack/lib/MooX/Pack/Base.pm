package MooX::Pack::Base;

use Moo::Role;
use Carp;

has [qw/raw_data data/] => (
	is => 'rw',
	lazy => 1,
);

has [qw/line_spec all_spec/] => (
	is => 'ro',
	builder => 1,
);

has [qw/pack_templates/] => (
	is => 'rw',
	builder => 1,
	lazy => 1
);

sub _build_pack_templates {
	my ($all, $line, @templates)  = ($_[0]->all_spec, $_[0]->line_spec);
	my %ordered_line = map { $line->{$_}->{index} => $line->{$_}->{spec} } keys %{ $line };
	for ( 0 .. ( scalar (keys %ordered_line) - 1 )) {
		push @templates, $ordered_line{$_};
	}
	for my $line ( @templates ) {
		my $push = scalar @{ $line };
		for (my $i = $push - 1; $i > 0; $i--) {
			splice @{ $line }, $i, 0, { %{ $all } };
		}
	}
	return \@templates;
}

sub build_pack_string {
	my ($spec, $string, @keys) = ($_[1], '');
	for (@{ $spec }) {
	        $string = sprintf('%s%s', $string, $_->{character});
		my $key = ($_->{key} || $_->{name});
		push @keys, $key if $key;
    	}
	return ($string, @keys);
}

sub unpack {
	my ($template, $line, @unpacking) = ($_[0]->pack_templates, 0);
	for($_[0]->raw_data =~ /([^\n]+)\n?/g){
		my ($pack_string, @keys) = $_[0]->build_pack_string($template->[$line]);
		my @unpack = unpack($pack_string, $_);
		my %hashed;
		@hashed{@keys} = @unpack;
		push @unpacking, \%hashed;
		$line++ if scalar @{$template} - 1 > $line;
	}
	$_[0]->data(\@unpacking);
	return \@unpacking;
}

sub pack {
	my ($template, $line, @packing) = ($_[0]->pack_templates, 0);
	for my $data (@{ $_[0]->data }) {
		my $pack;
		for (@{$template->[$line]}) {
			my $key = ($_->{key} || $_->{name});
			(my $sep = $_->{character}) =~ s/(x)/a/g; 
			$pack .= pack($sep, $key ? $data->{$key} : $_->{pack});
		}
		push @packing, $pack;
		$line++ if scalar @{$template} - 1 > $line;
	}
	my $packed = join "\n", @packing;  
	$_[0]->raw_data($packed);
	return $packed;
}

1;
