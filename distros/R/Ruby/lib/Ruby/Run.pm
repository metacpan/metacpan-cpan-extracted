package Ruby::Run;

use strict;
use warnings;

use Filter::Util::Call;

sub import{
	my $class = shift;
	filter_add({});
}

sub filter{
	my $self = shift;

	return 0 if $self->{eof};

	$_ = <<'HEAD' if $self->{line}++ == 0;
require Ruby;Ruby::rb_eval(<<'[RUBY]', __PACKAGE__, __FILE__, __LINE__-3);
HEAD

	my $status = filter_read();

	if($status == 0){ # EOF
		$_ .= "\n[RUBY]\n";
		$status = 1;
		$self->{eof} = 1;
	}
	return $status;
}
1;
__END__

=head1 NAME

Ruby::Run - Run Ruby script

=head1 SYNOPSIS

	use Ruby::Run;

	# write Ruby code

	def add(x, y)
		x + y
	end

	p add(1, 2) # => 3

=head1 SEE ALSO

L<Ruby>.

=cut
