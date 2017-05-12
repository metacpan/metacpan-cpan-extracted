package Rest::HtmlVis::Events;

use strict;
use warnings;

use parent qw( Rest::HtmlVis::Key );

sub head {
	my ($self, $local) = @_;

	my $struct = $self->getStruct;
	my @data;
	foreach my $key (sort keys %$struct) {
		push @data, sprintf("[%s,%s]", $key, $struct->{$key});
	}

	my $static = $self->baseurl;

	return '<script language="javascript" type="text/javascript" src="'.$static.'/flot/jquery.flot.js"></script>
	<script language="javascript" type="text/javascript" src="'.$static.'/flot/jquery.flot.time.js"></script>
	<script language="javascript" type="text/javascript" src="'.$static.'/flot/jquery.flot.threshold.js"></script>
	<script type="text/javascript">
		$(function() {

			var d1 = ['.join(",",@data).'];

			function plotWithOptions(t) {
				$.plot("#placeholder", [{
					data: d1,
					color: "rgb(30, 180, 20)",
					threshold: {
						below: t,
						color: "rgb(200, 20, 30)"
					},
					lines: {
						steps: true
					}
				}]);
			}

			plotWithOptions(0);
		});
	</script>
	<style>
	.event-container {
		box-sizing: border-box;
		width: 850px;
		height: 450px;
		padding: 20px 15px 15px 15px;
		margin: 15px auto 30px auto;
		border: 1px solid #ddd;
		background: #fff;
		background: linear-gradient(#f6f6f6 0, #fff 50px);
		background: -o-linear-gradient(#f6f6f6 0, #fff 50px);
		background: -ms-linear-gradient(#f6f6f6 0, #fff 50px);
		background: -moz-linear-gradient(#f6f6f6 0, #fff 50px);
		background: -webkit-linear-gradient(#f6f6f6 0, #fff 50px);
		box-shadow: 0 3px 10px rgba(0,0,0,0.15);
		-o-box-shadow: 0 3px 10px rgba(0,0,0,0.1);
		-ms-box-shadow: 0 3px 10px rgba(0,0,0,0.1);
		-moz-box-shadow: 0 3px 10px rgba(0,0,0,0.1);
		-webkit-box-shadow: 0 3px 10px rgba(0,0,0,0.1);
	}

	.event-placeholder {
		width: 100%;
		height: 100%;
		font-size: 14px;
		line-height: 1.2em;
	}
	</style>
	'
}

sub html {
	return '
	<div class="col-lg-12">
		<div class="event-container">
			<div id="placeholder" class="event-placeholder"></div>
		</div>
	</div>
	'
};

1;
=encoding utf-8

=head1 AUTHOR

Václav Dovrtěl E<lt>vaclav.dovrtel@gmail.comE<gt>
