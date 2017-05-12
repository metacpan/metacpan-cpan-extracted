use utf8;
package Mojolicious::Plugin::DevexpressHelpers::Helpers;
$Mojolicious::Plugin::DevexpressHelpers::Helpers::VERSION = '0.163572';
#ABSTRACT: Helpers for Devexpress controls are defined here
use Modern::Perl;
use Mojo::ByteStream;
use MojoX::AlmostJSON qw(encode_json);
use constant DEBUG => 0;

#Not sure why C<out> function have to decode from utf8,
#but it make my day!
our $OUT_DECODE = 'UTF-8';
our $INDENT_BINDING = 0;

my @generic_controls = qw(
		Accordion
		ActionSheet
		Autocomplete
		Box
		CheckBox
		Calendar
		ColorBox
		ContextMenu
		DateBox
		DeferRendering
		FileUploader
		Gallery
		List
		LoadIndicator
		Lookup
		Map
		MultiView
		NavBar
		NumberBox
		Panorama
		Pivot
		PivotGrid
		PivotGridFieldChooser
		Popover
		ProgressBar
		RadioGroup
		RangeSlider
		Resizable
		ResponsiveBox
		Scheduler
		ScrollView
		SelectBox
		Slider
		Switch
		TabPanel
		Tabs
		TagBox
		TextArea
		TextBox
		TitleView
		Toast
		Toolbar
		TreeView
	);

#Helper method to export without prepending a prefix
my @without_prefix = qw( dxbuild required_assets require_asset indent_binding append_js prepend_js );

#Helper method to export with prepending a prefix
my @with_prefix = (qw( Button DataGrid Form Popup Menu LoadPanel Lookup ),
				   @generic_controls);


sub out{
	my $tag = shift;
	my $bytes = Mojo::ByteStream->new($tag);
	return $bytes->decode($OUT_DECODE) if defined $OUT_DECODE;
	return $bytes;
}

sub new{
	my $class = shift;
	my $self = bless { 
			next_id => 1,
			bindings => '',
			before_bindings => '',
			after_bindings => '',
		}, $class;
	return $self;
}

sub indent_binding{
	my $self = shift;
	$INDENT_BINDING = shift;
}

sub add_binding{
	my $self = shift;
	$self->{bindings} .= join "\n", @_;
}

sub next_id{
	my $self = shift;
	return "dxctl".($self->{next_id}++);
}

sub new_id{
	my ($c, $attrs) = @_;
	#should compute a new uniq id 
	$c->stash('dxHelper')->next_id;
}

sub dxbind{
	my ($c, $control, $id, $attrs, $extensions, $befores, $afters) = @_;
	#should return html code to be associated to the control
	$befores //=[];
	$afters  //=[];
	#http://stackoverflow.com/questions/9930577/jquery-dot-in-id-selector
	my $jquery_id = $id;
	$jquery_id =~ s{\.}{\\\\.}g;
	my $prepend = ref $attrs eq 'HASH' && delete $attrs->{prependTo};
	my $append  = ref $attrs eq 'HASH' && delete $attrs->{appendTo};
	my $binding = '';
	if($prepend || $append){
		$binding = '$(\'<div id="'.$id.'">\').'.$control.'(';
	}
	else{
		$binding = '$("#'.$jquery_id.'").'.$control.'(';
	}
    my @options;

	if (ref($attrs) eq 'HASH') {
		$binding .= '{';
		$binding .= "\n  " if $INDENT_BINDING;
		for my $k ( sort keys %$attrs){
			my $v = $attrs->{$k} // '';
			if(ref($v) eq 'SCALAR'){
				#unref protected scalar
				$v = $$v;
			}
			elsif ($v!~/^\s*(?:function\s*\()/) {
				$v =  encode_json $v;
			}
			push @options, "$k: $v";
		}
	}
	else{
		push @options, $attrs;
	}
    $binding .= join ",\n".($INDENT_BINDING?'  ':''), @options;
	$binding .= '}' if ref($attrs) eq 'HASH';
    $binding .= ')';
	$binding .= '.prependTo("'.$prepend.'")' if $prepend;
	$binding .= '.appendTo("'.$append.'")'   if $append;
	$binding .= ';' . ($INDENT_BINDING?"\n":"");
	#append some extensions (eg: dxdatagrid)
	$binding .= join ";\n".($INDENT_BINDING?'  ':''), @$extensions if defined $extensions;
	$c->stash('dxHelper')->add_binding($binding);
	my $html_code = "<div id=\"$id\"></div>";
	if($prepend || $append){
		$html_code = '';
	}
	out join('',@$befores, $html_code ,@$afters);
}


sub parse_attributs{
	my $c = shift;
	my @implicit_args = @{shift()};
	my %attrs;
	IMPLICIT_ARGUMENT:
	while(@_ and @implicit_args){
		my $ref = ref($_[0]);
		my $implicit = shift @implicit_args || '';
		last unless $ref =~ /^(?:|SCALAR)$/
		or (substr($implicit,0,1) eq '@' and $ref eq 'ARRAY')
		or (substr($implicit,0,1) eq '%' and $ref eq 'HASH')
		or (substr($implicit,0,1) eq '\\' and $ref eq 'REF')
		or (substr($implicit,0,1) eq '*');
		$implicit =~ s/^[\\\*\%\@]//;
		$attrs{ $implicit } = shift @_;
	}
	if(my $args = shift){
		if(ref($args) eq 'HASH'){
			NAMED_ARGUMENT:
			while(my($k,$v)=each %$args){
				$attrs{$k} = $v;
			}
		}
	}
	return \%attrs;
}	

sub dxmenu {
    my $c = shift;
	my $attrs = parse_attributs( $c, [qw(id @items onItemClick)], @_ );
	my $id = delete($attrs->{id}) // new_id( $c, $attrs );	
	dxbind( $c, 'dxMenu' => $id => $attrs);
}


sub dxloadpanel {
    my $c = shift;
	my $attrs = parse_attributs( $c, [qw(id message)], @_ );
	my $id = delete($attrs->{id}) // new_id( $c, $attrs );	
	dxbind( $c, 'dxLoadPanel' => $id => $attrs);
}


sub dxbutton {
    my $c = shift;
	my $attrs = parse_attributs( $c, [qw(id text onClick type)], @_ );
	my $id = delete($attrs->{id}) // new_id( $c, $attrs );	
	dxbind( $c, 'dxButton' => $id => $attrs);
}


sub dxdatagrid{
	my $c = shift;
	my $attrs = parse_attributs( $c, [qw(id dataSource)], @_ );
	my $id = delete($attrs->{id}) // new_id( $c, $attrs );
	my @extensions;
	#dxbind( $c, 'dxDataGrid' => $id => $attrs, [ $dataSource ]);
	if ($attrs->{dataSource} && ref($attrs->{dataSource}) eq '') {
		my $dataSource = delete $attrs->{dataSource};
		#push @extensions, '$.getJSON("' . $dataSource . '",function(data){$("#'.$id.'").dxDataGrid({ dataSource: data });});';
		#$attrs->{dataSource} = \'[]';	#protect string to be "stringified" within dxbind

		#\"" is to protect string to be "stringified" within dxbind
		$attrs->{dataSource} = \"{store:{type:'odata',url:'$dataSource'}}";
	}
	if (exists $attrs->{options}) {
		$attrs = $attrs->{options};
	}
	
	dxbind( $c, 'dxDataGrid' => $id => $attrs, \@extensions);
}


sub dxform{
	my $c = shift;
	my $attrs = parse_attributs( $c, [qw(id %formData @items)], @_ );
	my $id = delete($attrs->{id}) // new_id( $c, $attrs );
	
	dxbind( $c, 'dxForm' => $id => $attrs );
}


sub dxpopup{
	my $c = shift;
	my $attrs = parse_attributs( $c, [qw(id title contentTemplate)], @_ );
	my $id = delete($attrs->{id}) // new_id( $c, $attrs );
	
	dxbind( $c, 'dxPopup' => $id => $attrs );
}



sub mk_dxcontrol{
	my $dxControl = shift;
	my $generic = sub{
		my $c = shift;
		my $attrs = parse_attributs( $c, [qw(id value label)], @_ );
		my $id = delete($attrs->{id});
		if (my $name = $id) {
			$attrs->{name}=$name;
		}
		
		$id //= new_id( $c, $attrs );
	
		my (@before, @after);
		if(my $label = delete($attrs->{label})){
			push @before, '<div class="dx-field">';
			push @before, '<div class="dx-field-label">'.$label.'</div>';
			push @before, '<div class="dx-field-value">';
			push @after, '</div>';
			push @after, '</div>';
		}
		
		dxbind( $c, $dxControl => $id => $attrs, undef, \@before, \@after );	
	};
	
	{
		no strict 'refs';
		*{__PACKAGE__.'::'.lc $dxControl} = $generic;
	}
}


sub dxbuild {
	my $c    = shift;
	my %opts = @_;
	my $dxhelper = $c->stash('dxHelper') or return;
	if($dxhelper->{bindings}){
		out '<script language="javascript">'.
			($opts{js_prefix}//'$(window).on("load",function(){') .
			"\n".
			join("\n",
				 grep{ ($_//'') ne ''}
				 @$dxhelper{'before_bindings','bindings','after_bindings'}
			).
			"\n".
			($opts{js_sufix}//'});').'</script>';
	}
}


sub require_asset{
	my $c = shift;
	my $dxhelper = $c->stash('dxHelper') or return;
	
	push @{ $dxhelper->{required_assets} }, $_ for @_;
	
	return $c;
}


sub required_assets{
	my $c = shift;
	my $dxhelper = $c->stash('dxHelper') or return;
	my $required_assets = $dxhelper->{required_assets} // [];
	my $results = Mojo::ByteStream->new();
	ASSET:
	for my $asset (@$required_assets){
		#not sure about how to simulate " %= asset 'resource' " that we can use in template rendering, 
		#nor how to output multiple Mojo::ByteStream objets at a time (is returning required ?)
		$$results .= ${ $c->asset($asset) };
	}
	return $results;
}

sub prepend_js{
	my ($c, @js) = @_;
	my $dxhelper = $c->stash('dxHelper') or return;
	for(@js){
		$dxhelper->{before_bindings} .= "\n" if $INDENT_BINDING;
		$dxhelper->{before_bindings} .= $_;
	}
}


sub append_js{
	my ($c, @js) = @_;
	my $dxhelper = $c->stash('dxHelper') or return;
	for(@js){
		$dxhelper->{after_bindings} .= "\n" if $INDENT_BINDING;
		$dxhelper->{after_bindings} .= $_;
	}
}

sub register {
	my ( $self, $app, $args ) = @_;
	my $tp = $args->{tag_prefix};
	
	#build generic dx-controls
	mk_dxcontrol( "dx$_" ) for @generic_controls;
	
	SUB_NO_PREFIX:
	for my $subname ( @without_prefix ){
		my $lc_name = lc $subname;
		my $sub = __PACKAGE__->can( $lc_name );
		unless($sub){
			$app->log->debug(__PACKAGE__." helper '$lc_name' does not exists!");
			next SUB_NO_PREFIX;
		}
		$app->helper( $lc_name => $sub );
	}

	SUB_WITH_PREFIX:
	for my $subname ( @with_prefix ){
		my $lc_name = lc $subname;
		my $sub = __PACKAGE__->can( 'dx' . $lc_name );
		unless($sub){
			$app->log->debug(__PACKAGE__." helper 'dx$lc_name' does not exists!");
			next SUB_WITH_PREFIX;
		}
		say STDERR "## adding helper '$tp$lc_name'" if DEBUG;
		$app->helper( $tp . $lc_name => $sub );
		say STDERR "## adding helper '$tp$subname'" if DEBUG and $args->{tag_camelcase};
		$app->helper( $tp . $subname => $sub ) if $args->{tag_camelcase};
	}
	
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::DevexpressHelpers::Helpers - Helpers for Devexpress controls are defined here

=head1 VERSION

version 0.163572

=head1 SUBROUTINES/METHODS

=head2 out

Output string in template

	out '<div id="'.$id.'"></div>';

=head2 new

Internal usage.

	my $dxHelper = Mojolicous::Plugin::DevexpressHelpers::Helpers->new;
	$c->stash( dxHelper => $dxHelper );

=head2 indent_binding

	$dxHelper->indent_binding( 1 );

=head2 add_binding

Internal usage.

	$dxHelper->add_binding($binding, [$binding2,...] );

=head2 next_id

Internal usage.

	my $next_id_number = $dxHelper->next_id;

=head2 new_id

Internal usage.

	my $new_id = $dxHelper->new_id;

=head2 dxbind

Internal usage.

	dxbind( $c, 'dxButton' => $id => $attrs, \@extensions);

Produce a div tag with an computed id, which will be binded to
a dxButton with C<$attrs> attributs at call to dxbuild.

=head2 parse_attributs

Internal usage

	my $attrs = parse_attributs( $c, \@implicit_arguments, @attributs )

=head2 dxmenu C< $id, \@items ,[ \%options ]>

	%= dxmenu mainMenu => [{ id => 1, text => 'Back', iconSrc => '/images/back.png', link => 'javascript:location.back();' }], \q% function(e){return e.itemData.link;} %

=head2 dxloadpanel C<[ $id, [ $message ] ], [ \%options ]>

	%= dxloadpanel myLoadPanel => 'Please wait'

=head2 dxbutton C<[ $id, [ $text, [ $onclick ] ] ], [ \%options ]>

	%= dxbutton myButtonId => 'My button' => q{ function (){ alert('onClick!'); } }
	
	%= dxbutton undef, 'My button' => '/some/url'
	
	%= dxbutton {
			id      => myId,
			text    => 'My button',
			onClick => q{ function (){ alert('onClick!'); } },
			type    => 'danger',
			icon    => 'user'
		};

=head2 dxdatagrid C<[ $id, [ $datasource, ] ] [ \%opts ]>

	%= dxdatagrid 'myID' => '/products.json', { columns => [qw( name description price )] }
	
	%= dxdatagrid undef, '/products.json'
	
	%= dxdatagrid { id => myId, dataSource => '/products.json' }

The following syntaxe allow to specify all options from a javascript object.
B<Note: It will ignore all other options specified in the hash reference.>

	%= dxdatagrid myId, { options => 'JSFrameWork.gridsOptions.myResource' }

=head2 dxform C<[ $id, [ $formData, [ \@itemsSpecs ], [ \%opts ] ] ]>

	%= dxform myForm => \%formData;
	
	%= dxform myForm => \%formData, { colCount => 2 };
	
	%= dxform myForm => \%formData, \%itemsSpecs;
	
	%= dxform myForm => \%formData, \%itemsSpecs, { colCount => '3' };

=head2 dxpopup C<[ $id, [ $title, [ $contentTemplate, ] ] ], [\%opts]>

	%= dxpopup myPopupID => 'Popup Title', \q{function(contentElement){
			contentElement.append('<p>Hello!</p>');
		}};

=head2 mk_dxcontrol C<$dxControlName>

In this package:

	mk_dxcontrol('dxNumberBox');
	mk_dxcontrol('dxSwitch');
	mk_dxcontrol('dxTextBox');
	mk_dxcontrol('dxLookup');
	mk_dxcontrol('dxSelectBox');

In your template:

	%= dxnumberbox 'age' => $value => 'Age: ', { placeHolder => 'Enter your age' }
	%= dxswitch 'mySwitch' => $boolean_value => 'Enabled: '
	%= dxtextbox 'name' => $value => 'Name: ', { placeHolder => 'Type a name' }
	%= dxlookup 'name' => $value => 'Name: ', { dataSource => $ds, valueExpr=> $ve, displayExpr => $de }
	%= dxselectbox 'name' => $value => 'Name: ', { dataSource => $ds, valueExpr=> $ve, displayExpr => $de }

=head2 dxbuild C<[ js_prefix => '$(function(){', js_sufix => '});' ]>

Build the binding between jQuery and divs generated by plugin helpers such as dxbutton.
It is should to be called in your template just before you close the body tag.
Optional named argument C<js_prefix> and C<js_sufix> can be specified to override
standard javascript wrapper.

	<body>
		...
		%= dxbuild
	</body>

=head2 require_asset @assets

Used to specify one or more assets dependencies, that will be appended on call to required_assets.
This function need 'AssetPack' plugin to be configurated in your application.

in your template:

	<body>
		...
		%= require_asset 'MyScript.js'
		...
	</body>

in your layout:

	<head>
		...
		%= required_assets
		...
	</head>

=head2 required_assets

Add assets that was specified by calls to require_asset.
See require_asset for usage.

=head2 prepend_js

Prepend javascript code to dx-generated code

	append_js 'alert("before dx-controls initialisation");'

=head2 append_js 

Append javascript code to dx-generated code

	append_js 'alert("after dx-controls initialisation");'

=head2 register

Register our helpers

=head1 AUTHOR

Nicolas Georges <xlat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Nicolas Georges.

This is free software, licensed under:

  The MIT (X11) License

=cut
