package Plack::Middleware::Debug::HTML::Mason;
$Plack::Middleware::Debug::HTML::Mason::VERSION = '0.3';
use strict;
use warnings;

use parent qw(Plack::Middleware::Debug::Base);

=head1 NAME

Plack::Middleware::Debug::HTML::Mason - Debug info for old HTML::Mason apps.

=head1 VERSION

version 0.3

=head1 SYNOPSIS

	# add this to your mason configuration
	plugins => ['Plack::Middleware::Debug::HTML::Mason::Plugin']
	
	# and then enable the middleware
	enable 'Debug::HTML::Mason';

=head1 DESCRIPTION

Provides a call tree and some basic configuration information for a request
processed by HTML::Mason.  To use this panel the included plugin
C<Plack::Middleware::Debug::HTML::Mason::Plugin> must be called by Mason.  If
this panel is enabled, the C<psgi.middleware.debug.htmlmason> key will be set
in the psgi environment.  This might be useful if you want load the plugin as
needed:

		if ($env->{'psgi.middleware.debug.htmlmason'}) {
			$handler->interp->plugins(['Plack::Middleware::Debug::HTML::Mason::Plugin']);
		}
		else {
			$handler->interp->plugins([]);
		}
		
		...

=cut

my $root;
my @stack;
my %env;
my $ran;

package Plack::Middleware::Debug::HTML::Mason::Plugin {
	use strict;
	use warnings;
	use parent qw(HTML::Mason::Plugin);
	use Time::HiRes qw(time);
	use JSON;

	my $json = JSON->new->convert_blessed(1)->allow_blessed(1)->allow_unknown(1)->utf8(1);
	
	sub start_component_hook {
		my ($self, $context) = @_;
		
		my $frame = {
			start => time(),
			kids  => [],
		};
		$root ||= [$frame];
		if (@stack) {
			my $parent= $stack[-1];
			push @{$parent->{kids}}, $frame;
		}
		push @stack, $frame;
	}
	
	sub end_component_hook {
		my ($self, $context) = @_;
		
		my $frame = pop @stack;
		my $name  = $context->comp->title;
		
		my ($path, $root, $method) = $name =~ m/(.*) (\[.+?\])(:.+)?/;
		
		$frame->{name} = $method ? "$root $path$method" : "$root $path";
		$frame->{end}  = time();
		$frame->{duration} = $frame->{end} - $frame->{start};
		$frame->{args} = $json->encode($context->args);
	}
	
	sub end_request_hook {
		my ($self, $context) = @_;
		
		$env{main_comp} = $context->request->request_comp;
		$env{args}      = $context->args;
		$env{comp_root} = $context->request->interp->comp_root;
		$ran = 1;
	}

}

 
sub run {
	my ($self, $env, $panel) = @_;
	
	$root  = undef;
	@stack = ();
	%env   = ();
	$ran   = 0;
	$env->{'psgi.middleware.debug.htmlmason'} = 1;
	
	return sub {
		my $res = shift;
		
		$panel->nav_title("HTML::Mason");
		$panel->title("HTML::Mason Summary");
		
		unless ($ran) {
			$panel->content('<h2 style="margin-top: 20px;">No Data</h2><p>No data was recorded by the mason plugin.  Make sure mason is configured to use the <code>Plack::Middleware::Debug::HTML::Mason::Plugin</code> plugin.</p>');
			return;
		}
		
		
		my $depth  = 0;
		my $frame;
		my $walker;
		my $html = '';
		my $i = 0;
		$walker = sub {
			my ($context, $depth) = @_;
			return unless $context && @$context;

			
			foreach my $frame (@$context) {
				my $margin = sprintf("%dpx", $depth * 16);
				my $background;
				$i++;
				if ($i % 2) {
					$background = '#f5f5f5';
				}
				elsif ($frame->{name} eq $env{main_comp}->title) {
					$background = '#f0f0f0';
				}
				else {
					$background = 'white';
				}
				
				$html .= sprintf('<div style="background-color: %s; padding-left: %s">%s(%s) - %.5fs</div>',
					$background,
					$margin,
					$frame->{name},
					$frame->{args},
					$frame->{duration},
				);
				
				$walker->($frame->{kids}, $depth + 1);				
			}
		};
		
		$walker->($root, 1);
		
		my $css = <<END;
<style type="text/css">
	div#mason_debug  {
		margin-top: 16px;
		background: white;
		border: solid 1px #ddd;
	}
	
	div#mason_debug div {
		padding-top: 2px;
		padding-bottom: 2px;
	}
</style>
END
		
		$panel->content(
			$self->render_list_pairs([
				'Main Comp' => $env{main_comp}->source_file,
				'Args'      => $env{args},
				'Comp Root' => $env{comp_root},
				
			]) . 
			qq|$css<div id="mason_debug">$html</div>|
		);
	};
}



=head1 TODO

=over 2

=item *

The docs are pretty middling at the moment.

=back

=head1 AUTHORS

    Chris Reinhardt
    crein@cpan.org

    David Hand
    cogent@cpan.org
    
=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

L<Plack::Middleware::Debug>, L<HTML::Mason>, perl(1)

=cut

1;
$Plack::Middleware::Debug::HTML::Mason::Plugin::VERSION = '0.3';
__END__
