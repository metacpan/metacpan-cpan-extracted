package Rest::HtmlVis::Content;

use 5.006;
use strict;
use warnings FATAL => 'all';

use parent qw( Rest::HtmlVis::Key );

use Plack::Request;
use YAML::Syck;
use URI::Escape::XS qw/decodeURIComponent/;
use Encode;

$YAML::Syck::ImplicitUnicode = 1;

=head1 NAME

Rest::HtmlVis::Content - Return base block for keys links and form.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.13';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Rest::HtmlVis::Content;

    my $foo = Rest::HtmlVis::Content->new();
    ...

=head1 KEYS

=head2 link

Convert default strcuture of links. Each link should consists of:

=over 4

=item * href

URL of target.Can be absolute or relative.

=item * title

Name of the link.

=item * rel

Identifier of the link (type of the link)

=back

Example:

	link => [
		{
			href => '/api/test',
			title => 'Test resource',
			rel => 'api.test'
		}
	]

=head2 form

Define elements of formular for html.

=cut

my @defualtMethods = ('get','post','put','delete');

sub setStruct {
	my ($self, $key, $struct, $env) = @_;
	$self->{struct} = $struct;
	$self->{env} = $env;

	return 1;
}

sub getOrder {
	return 9999;
}

sub newRow {
	return 1;
}

sub head {
 return <<END;
	<script type="text/javascript">
		\$('#myTab a').click(function (e) {
		  e.preventDefault();
		  \$(this).tab('show');
		});
	function sendPut(methodType,url,jsvar){
		var selected = \$( "select[name*='enctype'] option:selected" ).val();
		var enctype = typeof selected == 'undefined'?'application/json':'application/x-www-form-urlencoded';
		\$.ajax({
			type: methodType,
			url: url,
			headers: {          
			                 Accept : 'application/json; charset=utf-8',         
			                'Content-Type': enctype + '; charset=utf-8'   
			},
			success: function(data) {
				alert('Success'); 
				window.location.href=url;
			},
			error: function(data) {
				alert(data.responseText);
			},
			data: jsvar
		});return false;
	}
	</script>
END
}

sub onload {
	'prettyPrint();'
}

sub html {
	my ($self) = @_;
	my $struct = $self->getStruct;
	my $env = $self->getEnv;

	### Links
	my $links = '';
	if (ref $struct eq 'HASH' && exists $struct->{link} && ref $struct->{link} eq 'ARRAY'){
		foreach my $link (@{$struct->{link}}) {
			$links .= '<li><a href="'.$link->{href}.'" rel="'.$link->{rel}.'">'.$link->{title}.'</a></li>';
		}
		delete $struct->{link};
	}

	### Remove form content
	my $formStruct; # Set undef
	$formStruct = delete $struct->{form} if (ref $struct eq 'HASH' && exists $struct->{form} && ref $struct->{form} eq 'HASH');

	### Content
	my $content = '';
	{
		local $Data::Dumper::Indent=1;
		local $Data::Dumper::Quotekeys=0;
		local $Data::Dumper::Terse=1;
		local $Data::Dumper::Sortkeys=1;

		$content = Dump($struct);
	}

	if( !$formStruct && exists $env->{'REST.class'} && $env->{'REST.class'}->can('GET_FORM') ){
		my $req = Plack::Request->new($env);
 		my $par = $req->parameters;
		$formStruct = $env->{'REST.class'}->GET_FORM($env, $content, $par);
	}

	### Form
	my $form = {};
	my $extForm = {};
	if ($formStruct){
		$form = _formToHtml($env,$formStruct,@defualtMethods);
	}
	if($formStruct){
		$extForm = _extFormToHtml($env,$formStruct,(keys %{$formStruct}));
	}
	my $firstActive = 'get';
	foreach my $method (@defualtMethods){
		if ($form->{$method}){
			$firstActive=$method;
			last;
		}
	}

	if( exists $env->{'REST.class'} && $env->{'REST.class'}->can('GET') and !exists $form->{get}){
		$form->{get} = _formToHtml($env, {get => {}}, ('get') )->{get};
	}

	my $ret = "
		<div class=\"col-lg-3\">";

			if( keys %{$extForm} ){
				$ret .= "			
							<!-- Nav tabs -->
							<ul id=\"myTabExt\" class=\"nav nav-tabs nav-justified\" role=\"tablist\">";
					my @extkey = sort(keys %{$extForm});
					my $firstActiveExt = $extkey[0];
					foreach my $method (@extkey){
						$ret .="				<li role=\"presentation\"" . ( $firstActiveExt eq $method?" class=\"active\"":($extForm->{$method}?'':" class=\"disabled\"")) . "><a role=\"tab\"". ($extForm->{$method}?" href=\"#$method\" data-toggle=\"tab\"":'') . ">" . uc($method) . "</a></li>";
					}
					$ret .= "			<!-- Tab panes -->
							<div class=\"tab-content\" id=\"myTabContent\">";
					foreach my $method (@extkey){
						my $extForPar = $extForm->{$method}{params};
						$ret .= "				<div role=\"tabpanel\" class=\"tab-pane fade" . ( $firstActiveExt eq $method?"  in active":'') . "\" id=\"$method\">
									<form class=\"method-form\" ". ($extForPar->{method} =~ /^(put|delete)$/i?"onSubmit=\""._getAjaxCall($self,  uc($extForPar->{method}),$extForPar):"method=\"" . uc($extForPar->{method})) . "\"" . (exists $extForPar->{url}?'action="'.$extForPar->{url}:'') . "\">".($extForm->{$method}{html}||'<div class="text-center"> Not allowed </div>')."
									</form>
								</div>";
					}
				  $ret .= "</div><hr />";
			}
	my $header = $self->getHeader;
	my $duration = sprintf ( "%.3f",$header->{'X-Runtime'} *1000);

  $ret .= " 			<ul class=\"links\">
				$links
			</ul>
		</div>
		<div class=\"col-lg-6\">
			<pre class=\"prettyprint lang-yaml\">
$content
			</pre>
			<div class=\"row align-right text-muted duration\"> <small>Duration: $duration ms </small></div>  
		</div>
		<div class=\"col-lg-3\" role=\"tabpanel\">

			<!-- Nav tabs -->
			<ul id=\"myTab\" class=\"nav nav-tabs nav-justified\" role=\"tablist\">";

	foreach my $method (@defualtMethods){
		$ret .="				<li role=\"presentation\"" . ( $firstActive eq $method?" class=\"active\"":(exists $form->{$method}?'':" class=\"disabled\"")) . "><a role=\"tab\"". (exists $form->{$method}?" href=\"#$method\" data-toggle=\"tab\"":'') . ">" . uc($method) . "</a></li>";
	}
	$ret .= "			<!-- Tab panes -->
			<div class=\"tab-content\" id=\"myTabContent\">";
	foreach my $method (@defualtMethods){
		$ret .= "				<div role=\"tabpanel\" class=\"tab-pane fade" . ( $firstActive eq $method?"  in active":'') . "\" id=\"$method\">
					<form class=\"method-form\" ". ($method =~ /^(put|delete)$/?"onSubmit=\""._getAjaxCall($self,  uc($method)):"method=\"" . uc($method)) . "\">".($form->{$method}||'<div class="text-center"> Not allowed </div>')."
					</form>
				</div>";
	}
	$ret .= "			</div></div>

		</div>
";
	return $ret;
}

sub _getAjaxCall {
	my ($self, $methodType, $params) = @_;
	my $jsvar = "\$(this).serialize()";
	my $url = $self->getEnv()->{REQUEST_URI};
	if (defined $params){
		$jsvar = $params->{jsvar} if exists $params->{jsvar};
		$url = $params->{url} if exists $params->{url};
	}
	return <<END;
	sendPut('$methodType','$url',$jsvar);
END
}


my $defaultForm = {
	get => 	"<label class=\"col-lg-4 control-label\">Get as</label> 
	<select name=\"format\" class=\"form-control\">
	  <option selected=\"selected\">text/html</option>
	  <option>application/json</option>
	  <option>text\/yaml</option>
	  <option>text/plain</option>
	</select>
	<button type=\"submit\" class=\"btn btn-default\">Get</button>",
	
	post => "<label class=\"col-lg-4 control-label\">Get as</label> 
	<select name=\"format\" class=\"form-control\">
	  <option selected=\"selected\">text/html</option>
	  <option>application/json</option>
	  <option>text/yaml</option>
	  <option>text/plain</option>
	</select>
	<label class=\"col-lg-4 control-label\">Post as</label> 
	<select name=\"enctype\" class=\"form-control\">
	  <option>application/json</option>
	  <option selected=\"selected\">text/yaml</option>
	  <option>text/plain</option>
	</select>
	<button type=\"submit\" class=\"btn btn-default\">Post</button>",

	put =>  "<label class=\"col-lg-4 control-label\">Put as</label> 
	<select name=\"enctype\" class=\"form-control\">
	  <option>application/json</option>
	  <option selected=\"selected\">text/yaml</option>
	  <option>text/plain</option>
	</select>
	<button type=\"submit\" class=\"btn btn-default\">Put</button>",

	delete => "<button type=\"submit\" class=\"btn btn-default\">Delete</button>",
};


sub _decodeQuery {
	my $str = shift || return {};
	my %ret;
	map
		{
			my ($a,$b) = split '=', $_, 2;
			unless ($a =~ /^(?:format|enctype)$/i) {
				$b =~ s/\+/ /g;
				$b = Encode::decode_utf8(decodeURIComponent($b));
				if (exists $ret{$a}) {
					$ret{$a} .= "|$b";
				} else {
					$ret{$a} = $b;
				}
			}
		}
		split '&', $str;
	return {%ret}
}

sub _paramsToHtml {
	my ($env, $param, $paramValue) = @_;
	my $type = $paramValue->{type};
	my $name = $param;
	next unless $name and $type;

	my $description = $paramValue->{description}||'';
	my $html = '';
	my $query = _decodeQuery($env->{QUERY_STRING});
	if(exists $query->{$name}){
		$paramValue->{default} = $query->{$name} =~ /\|/?[split '\|',$query->{$name}]:$query->{$name};
	}
	if ($type eq 'text'){
		my $default = ($paramValue->{default}||'');
		if (ref $default eq 'HASH' || ref $default eq 'ARRAY'){
			$default = YAML::Syck::Dump($default);
		}
		$html .= '<div class="form-group">';
		$html .= '<label>'.$description.'</label>' if ($description);
		$html .= '<input type="text" name="'.$name.'" class="form-control" value="'.$default.'"></input>';
		$html .= '</div>';
	}elsif ($type eq 'textarea'){
		my $rows = ($paramValue->{rows}||20);
		my $cols = ($paramValue->{cols}||3);
		my $default = ($paramValue->{default}||'');
		if (ref $default eq 'HASH' || ref $default eq 'ARRAY'){
			$default = YAML::Syck::Dump($default);
		}
		$html .= '<div class="form-group">';
		$html .= '<label>'.$description.'</label>' if ($description);
		$html .= '<textarea class="form-control" name="'.$name.'" rows="'.$rows.'" cols="'.$cols.'">'.$default.'</textarea>';
		$html .= '</div>';
	}elsif ($type eq 'checkbox'){
		$html .= '<div class="form-group">';
		$html .= "<label >".$description.'</label>' if ($description);
			$paramValue->{options} = [$paramValue->{options}] if ( ref $paramValue->{options} ne "ARRAY");
			foreach my $v (@{$paramValue->{options}}){
				my $optionName = ''; my $value = '';
				if (ref $v eq 'ARRAY'){
					($optionName, $value) = @$v;
				}else{
					$optionName = $v; $value = $v;
				}
				my $checked='';
				if(exists $paramValue->{default}){
					if(ref $paramValue->{default} eq 'ARRAY'){
						foreach my $d (@{$paramValue->{default}}){
							$checked = 'checked="checked"'if ($d eq $value);
						}
					}else{
						$checked = 'checked="checked"'if ($paramValue->{default} eq $value);
					}
				}
				$html .= "<div class='checkbox'><label><input type='checkbox' value='$value' name='$name' $checked />&nbsp;$optionName</label></div>";
			}
			$html .= '</div>';
	}elsif ($type eq 'radio'){
		$html .= '<div class="form-group">';
		$html .= "<label>".$description.'</label>' if ($description);
			foreach my $v (@{$paramValue->{options}}){
				my $optionName = ''; my $value = '';
				if (ref $v eq 'ARRAY'){
					($optionName, $value) = @$v;
				}else{
					$optionName = $v; $value = $v;
				}
				my $checked='';
				if(exists $paramValue->{default}){
					if(ref $paramValue->{default} eq 'ARRAY'){
						foreach my $d (@{$paramValue->{default}}){
							$checked = 'checked="checked"'if ($d eq $value);
						}
					}else{
						$checked = 'checked="checked"'if ($paramValue->{default} eq $value);
					}
				}
				$html .= "<div class='radio'><label><input type='radio' value='$value' name='$name' $checked />$optionName</label></div>";
			}
			$html .= '</div>';
	}elsif ($type eq 'select'){
		$html .= '<div class="form-group">';
		$html .= '<label>'.$description.'</label>' if ($description);
		$html .= '<select class="form-control" name="'.$name.'">';
		foreach my $v (@{$paramValue->{options}}){
			my $name = ''; my $id = '';
			if (ref $v eq 'ARRAY'){
				($id, $name) = @$v;
			}else{
				$name = $v; $id = $v;
			}
			my $default = (defined $paramValue->{default} && $id eq $paramValue->{default}) ? 'selected="selected"' : '';
			$html .= '<option id="'.$id.'" '.$default.'>'.$name.'</option>';
		}
		$html .= '</select>';
		$html .= '</div>';
	}elsif ($type eq 'hidden'){
		$html .= "  <input type='hidden' name='$param' value='$paramValue->{default}' />";
		
	}
	return $html;
}

sub _extFormToHtml {
	my ($env, $struct, @methods) = @_;
	my $form = {};
	foreach my $defaultMethod (@methods) {
		my $method = delete $struct->{$defaultMethod};
		if (defined  $method and exists $method->{params} && ref $method->{params} eq 'HASH'){
			my $html = '';
			delete $method->{params}{format};
			#delete $method->{params}{ENCTYPE};
			foreach my $param (sort {($method->{params}{$a}{description}||$a) cmp ($method->{params}{$b}{description}||$b) } keys %{$method->{params}}) {
				$html .= _paramsToHtml($env, $param, $method->{params}{$param});
			}
			$form->{$defaultMethod}{html} .= $html;
		}
		if(defined  $method and  exists $method->{default}){
			my $html = '';
			$html .= '<textarea class="form-control" name="DATA" rows="20" cols="3">'.$method->{default}.'</textarea>';
			$form->{$defaultMethod}{html} .= $html;
		}
		delete $method->{params};
		$form->{$defaultMethod}{params} = $method;
		$form->{$defaultMethod}{html} .= $defaultForm->{lc ($method->{method}) } if exists $defaultForm->{ lc($method->{method}) };
	}

	return $form;
}

sub _formToHtml {
	my ($env,$struct, @methods) = @_;
	my $form = {};
	foreach my $defaultMethod (@methods) {
		my $method = delete $struct->{$defaultMethod};
		if (defined  $method and exists $method->{params} && ref $method->{params} eq 'HASH'){
			my $html = '';
			foreach my $param (sort {($method->{params}{$a}{description}||$a) cmp ($method->{params}{$b}{description}||$b) } keys %{$method->{params}}) {
				$html .= _paramsToHtml($env, $param, $method->{params}{$param});
			}
			$form->{$defaultMethod} .= $html;
		}
		if(defined  $method and  exists $method->{default}){
			my $html = '';
			$html .= '<textarea class="form-control" name="DATA" rows="20" cols="3">'.$method->{default}.'</textarea>';
			$form->{$defaultMethod} .= $html;
		}
		
		$form->{$defaultMethod} .= $defaultForm->{$defaultMethod} if defined $method;
	}

	return $form;
}

=encoding utf-8

=head1 AUTHOR

Václav Dovrtěl E<lt>vaclav.dovrtel@gmail.comE<gt>

=head1 BUGS

Please report any bugs or feature requests to github repository.

=head1 ACKNOWLEDGEMENTS

Inspired by L<https://github.com/towhans/hochschober>

=head1 REPOSITORY

L<https://github.com/vasekd/Rest-HtmlVis>

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Vaclav Dovrtel.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1; # End of Rest::HtmlVis::Content
