package Puzzle::Debug;

our $VERSION = '0.16';

use base 'Class::Container';

use Data::Dumper;
use HTML::Entities;
use Time::HiRes qw(gettimeofday tv_interval);



use HTML::Mason::MethodMaker(
	read_only 		=> [ qw(timer) ],
);

sub sprint {
	my $self	= shift;
	my $tmpl	= $self->container->tmpl;
	my $html	= &Puzzle::Debug::debug_html_code();
	$tmpl->tmplfile(\$html);
	return $tmpl->html({$self->internal_objects_dump_for_html});
}

sub timer_reset {
	my $self	= shift;
	$self->{timer} = [gettimeofday];
}

sub internal_objects_dump_for_html {
	my $self		= shift;
  my $glob		= $self->all_mason_args_for_debug;
  my %debug;
  my $to_dump = sub { $_[0] =~ s/^\$VAR1\s*=\s*//;
                      $_[0] =~ s/(\'pw\'\s*\=\>\s*\'[^']+)/'pw' => '********/;
                      $_[0] =~ s/(\'password\'\s*\=\>\s*\'[^']+)/'password' => '********/;
                      $_[0] = encode_entities($_[0]);
                      $_[0] =~ s/\n/<br>/g;
                      $_[0] =~ s/\s/&nbsp;/g;
                      return $_[0]};
	$debug{debug_elapsed}	= tv_interval($self->timer);
  foreach my $key (qw/conf post args session env/) {
		delete $glob->{$key}->{container};
    foreach (sort {lc($a) cmp lc($b)} keys %{$glob->{$key}}) {
      my $dumper = &$to_dump(Data::Dumper::Dumper($glob->{$key}->{$_}));
      push @{$debug{"debug_$key"}},{ key => $_,value =>  $dumper};
    }
  }
  foreach (keys %{$self->container->post->args}) {
      my $dumper = &$to_dump(Data::Dumper::Dumper($self->container->post->args->{$_}));
      push @{$debug{"debug_http_post"}},{ key => $_,value =>  $dumper};
  }
  push @{$debug{"debug_cache"}}, {key => 'size',
    value => $self->container->_mason->cache(namespace=>$self->container->cfg->namespace)->size};
  my @cache_keys =$self->container->_mason->cache(namespace=>$self->container->cfg->namespace)->get_keys;
  foreach (@cache_keys) {
    push @{$debug{"debug_cache"}},
      {key => $_, value => &ParseDateString("epoch " .
        $self->container->_mason->cache(namespace=>$self->container->cfg->namespace)->get_object($_)->get_expires_at())};
  }	
	$debug{'puzzle_dump'} = $to_dump->(Data::Dumper::Dumper($self->container));
  return %debug
}

sub all_mason_args {
	# ritorna tutti i parametri globali
	# alcuni normalizzati
	my $self	= shift;
	my $puzzle	= $self->container;
	return { 
			%{$puzzle->cfg->as_hashref}, 
			%{&_struct2args($puzzle->session->internal_session)},
	  		%{&_struct2args($puzzle->post->args)},
			%{&_struct2args($puzzle->args->args)}, 
			title => $puzzle->page->title,
	};
}

sub all_mason_args_for_debug {
	# ritorna tutti i parametri globali
	# alcuni normalizzati
	my $self  = shift;
	return { 
		conf 	=> $self->container->cfg,
		session => &_struct2args($self->container->session->internal_session),
    	post 	=> &_struct2args($self->container->post->args) ,
		args 	=> &_struct2args($self->container->args->args),
		env		=> 	\%ENV
	};
}

sub _struct2args {
	my $struct = shift;
	my $buffer = {};
	&_struct2argsrec(\$buffer,$struct,'');
	return $buffer;
}

sub _struct2argsrec {
	my $buffer		= shift;
	my $struct	 	= shift;
	my $key			= shift;
	if (ref($struct) eq 'HASH') {
		$key .= '.' unless ($key eq '');
		foreach (keys %$struct) {
			&_struct2argsrec($buffer,$struct->{$_},"$key$_");
		}
	} elsif (ref($struct) eq 'ARRAY') {
		if (defined($struct->[0]) && ref($struct->[0]) eq '') {
			# it's not an array of hashref
			$$buffer->{"$key.array.count"} = scalar(@$struct);
			$key = "$key.array.";
			for (my $i=0;$i<scalar(@$struct);$i++) {
				&_struct2argsrec($buffer,$struct->[$i],"$key$i");
			}
		} else {
			$$buffer->{$key} = $struct;
		}
	} elsif (ref($struct) eq '') {
		$$buffer->{$key} = $struct;
	} else {
		die "_struct2argsrec: Unknown structure for key $key: " . ref($struct) .
		Data::Dumper::Dumper($struct);
	}
}

sub debug_html_code {
	return <<EOF;
<!-- required debug.css and debug.js -->

<!-- INIT: DEBUG TABBED -->
<ul id="tablist">

<li><a href="#" class="current" onClick="return expandcontent('sc1', this)">DEBUG MENU</a></li>
<li><a href="#" onClick="return expandcontent('sc2', this)" theme="#EAEAFF">POST HTTP</a></li>
<li><a href="#" onClick="return expandcontent('sc3', this)" theme="#EAEAFF">Al template</a></li>
<li><a href="#" onClick="return expandcontent('sc4', this)" theme="#FFE6E6">Al template dal POST HTTP</a></li>
<li><a href="#" onClick="return expandcontent('sc5', this)" theme="#DFFFDF">Sessione</a></li>
<li><a href="#" onClick="return expandcontent('sc6', this)" theme="#AFAFAF">Configurazione</a></li>
<li><a href="#" onClick="return expandcontent('sc7', this)" theme="#D0F0D0">Ambiente</a></li>
<li><a href="#" onClick="return expandcontent('sc8', this)" theme="#BFBFDF">Cache</a></li>
<li><a href="#" onClick="return expandcontent('sc9', this)" theme="#FF9F9F">Puzzle</a></li>
</ul>

<DIV id="tabcontentcontainer">

<div id="sc1" class="tabcontent">
Pagina valutata in <b>%debug_elapsed%</b> secondi.<br />
</div>

<div id="sc2" class="tabcontent">
<table border="0">
<TMPL_LOOP NAME="debug_http_post">
        <tr>
        <td valign="top" >
<font color="#0000FF" class="debugcella">%key%</font></td>
        <td valign="top" class="debugcella"> 
        =&gt;</td> <td valign="top" class="debugcella">
        %value% </td>
        </tr>
</TMPL_LOOP>
</table>
</div>

<div id="sc3" class="tabcontent">
<table border="0">
<TMPL_LOOP NAME="debug_args">
        <tr>
        <td valign="top" >
<font color="#0000FF" class="debugcella">%key%</font></td>
        <td valign="top" class="debugcella"> 
        =&gt;</td> <td valign="top" class="debugcella">
        %value% </td>
        </tr>
</TMPL_LOOP>
</table>

</div>

<div id="sc4" class="tabcontent">
<table border="0">
<TMPL_LOOP NAME="debug_post">
        <tr>
        <td valign="top" >
<font color="#0000FF" class="debugcella">%key%</font></td>
        <td valign="top" class="debugcella"> 
        =&gt;</td> <td valign="top" class="debugcella">
        %value% </td>
        </tr>
</TMPL_LOOP>
</table>
</div>

<div id="sc5" class="tabcontent">
<table border="0">
<TMPL_LOOP NAME="debug_session">
        <tr>
        <td valign="top">
<font color="#0000FF" class="debugcella">%key%</font></td>
        <td valign="top" class="debugcella"> 
        =&gt;</td> <td valign="top" class="debugcella">
        %value%</td>
</tr>
</TMPL_LOOP>
</table>

</div>
<div id="sc6" class="tabcontent">
<table border="0">
<TMPL_LOOP NAME="debug_conf">
        <tr>
        <td valign="top" >
<font color="#0000FF" class="debugcella">%key%</font></td>
        <td valign="top" class="debugcella"> 
        =&gt;</td> <td valign="top" class="debugcella">
        %value% </td>
        </tr>
</TMPL_LOOP>
</table>
</div>

<div id="sc7" class="tabcontent">
<table border="0">
<TMPL_LOOP NAME="debug_env">
        <tr>
        <td valign="top" >
<font color="#0000FF" class="debugcella">%key%</font></td>
        <td valign="top" class="debugcella"> 
        =&gt;</td> <td valign="top" class="debugcella">
        %value% </td>
        </tr>
</TMPL_LOOP>
</table>
</div>
<div id="sc8" class="tabcontent">
<table border="0">
<TMPL_LOOP NAME="debug_cache">
        <tr>
        <td valign="top" >
<font color="#0000FF" class="debugcella">%key%</font></td>
        <td valign="top" class="debugcella"> 
        =&gt;</td> <td valign="top" class="debugcella">
        %value% </td>
        </tr>
</TMPL_LOOP>
</table>
</div>

<div id="sc9" class="tabcontent">
<font color="#000000" class="debugcella">
<PRE>
%puzzle_dump%
</PRE>
</font>
</div>


</DIV>
EOF
}

1;
