package Rest::HtmlVis::Footer;
use parent qw( Rest::HtmlVis::Key );
	
use YAML::Syck;

our $VERSION = '0.08';

sub setStruct {
	my ($self, $key, $struct, $env) = @_;
	$self->{struct} = $struct;
	$self->{env} = $env;
	return 1;
}

sub getOrder {
	return infinity;
}

sub blocks {
	return 0;
}

sub head{
'<style>
	.footer {
		margin-top: 10px;
		width: 100%;
		background-color: #FFFFFF;
	}
</style>
'

}
sub html {
	my ($self) = @_;
	local $Data::Dumper::Indent=1;
	local $Data::Dumper::Quotekeys=0;
	local $Data::Dumper::Terse=1;
	local $Data::Dumper::Sortkeys=1;
	my $header = $self->getHeader;
	my $duration = sprintf ( "%.3f",$header->{'X-Runtime'} *1000);
	my $html = <<END;
<footer class="footer text-muted ng-scope"></footer>
END
	return $html;
}
