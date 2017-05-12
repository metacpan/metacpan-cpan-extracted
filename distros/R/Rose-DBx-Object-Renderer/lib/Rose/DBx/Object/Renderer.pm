package Rose::DBx::Object::Renderer;
use strict;
use warnings;
no warnings 'uninitialized';
use Exporter 'import';

use base qw(Rose::Object);
our @EXPORT = qw(config load);
our @EXPORT_OK = qw(config load render_as_form render_as_table render_as_menu render_as_chart stringify_me stringify_class delete_with_file prepare_renderer);
our %EXPORT_TAGS = (object => [qw(render_as_form stringify_me stringify_class delete_with_file prepare_renderer)], manager => [qw(render_as_table render_as_menu render_as_chart)]);

use Lingua::EN::Inflect ();
use DateTime;
use Rose::DB::Object::Loader;
use Rose::DB::Object::Helpers ();
use CGI;
use CGI::FormBuilder;
use Template;
use File::Path;
use File::Copy;
use File::Copy::Recursive ();
use File::Spec;
use Digest::MD5 ();
use Scalar::Util ();
use Clone qw(clone);

our $VERSION = 0.77;
# 264.65

sub _config {
	my $config = {
		db => {name => undef, type => 'mysql', host => '127.0.0.1', port => undef, username => 'root', password => 'root', tables_are_singular => undef, table_prefix => undef, new_or_cached => 1, check_class => undef},
		template => {path => 'templates', url => 'templates', options => undef},
		upload => {path => 'uploads', url => 'uploads', keep_old_files => undef},
		form => {download_message => 'View', remove_message => 'Remove', remove_files => undef, cancel => 'Cancel', delimiter => ',', action => undef},
		table => {search_result_title => 'Search Results for "[% q %]"', empty_message => 'No Record Found.', no_pagination => undef, per_page => 15, pages => 9, or_filter => undef, like_filter => undef,  delimiter => ', ', keyword_delimiter => ',', , like_operator => undef, cascade => ['template_url', 'template_path', 'template_options', 'query', 'renderer_config', 'prepared'], form_options => ['before', 'order', 'fields', 'template']},
		menu => {cascade => ['create', 'edit', 'copy', 'delete', 'ajax', 'prepared', 'searchable', 'template_url', 'template_path', 'template_options', 'query', 'renderer_config']},
		misc => {time_zone => 'Australia/Sydney', stringify_delimiter => ' ', doctype => '<!DOCTYPE HTML>', html_head => '<style type="text/css">body,div,dl,dt,dd,ul,ol,li,h1,h2,h3,h4,h5,h6,pre,form,fieldset,input,textarea,p,blockquote,th,td{margin:0;padding:0;}table{border-collapse:collapse;border-spacing:0;}fieldset,img{border:0;}address,caption,cite,code,dfn,em,strong,th,var{font-style:normal;font-weight:normal;}ol,ul{list-style:none;}caption,th{text-align:left;}h1,h2,h3,h4,h5,h6{font-size:100%;font-weight:normal;}q:before,q:after{content:\'\';}abbr,acronym{border:0;}body{font-size:93%;font-family:"Lucida Grande",Helvetica,Arial,Verdana,sans-serif;color:#222;}a,a:hover{color:#1B80BB;text-decoration:none;}a:hover{color:#0D3247;}a.button{white-space:nowrap;background-color:rgba(0,0,0,0.05);padding:5px 8px;-moz-border-radius:4px;-webkit-border-radius:4px;border-radius:4px;-moz-transition:background-color 0.2s linear;-webkit-transition:background-color 0.2s linear;-o-transition:background-color 0.2s linear;}a.button:hover{background-color:rgba(0,0,0,0.25);color:rgba(255,255,255,1);-webkit-box-shadow:0px 0px 3px rgba(0,0,0,0.1);-moz-box-shadow:0px 0px 3px rgba(0,0,0,0.1);box-shadow:0px 0px 3px rgba(0,0,0,0.1);}a.button:active{background-color:rgba(0,0,0,0.4);}a.delete{color:#BA1A1A;}p{padding:10px 20px;}form td{border:0px;text-align:left;}form tr:hover{background-color:rgba(255,255,255,0.1);}.fb_required{font-weight:bold;}.fb_error,.fb_invalid,.warning{color:#BA1A1A;}label{color:#333;}input,textarea,select{font-size:100%;font-family:"Lucida Grande",Helvetica,Arial,Verdana,sans-serif;color:#333;background-color:rgba(255,255,255,0.3);border:1px solid #DDD;margin:0px 5px;padding:4px 8px;-moz-border-radius:4px;-webkit-border-radius:4px;border-radius:4px;}input[type="text"],input[type="password"],select,textarea {-webkit-transition:border 0.2s linear,-webkit-box-shadow 0.2s linear;-moz-transition:border 0.2s linear,-moz-box-shadow 0.2s linear;-o-transition:border 0.2s linear,box-shadow 0.2s linear;}input[type="text"]:focus,input[type="password"]:focus,select:focus,textarea:focus {outline:none;border:1px solid #BBB;-webkit-box-shadow:0 0 6px rgba(0,0,0,0.4);-moz-box-shadow:0 0 6px rgba(0,0,0,0.4);box-shadow:0 0 6px rgba(0,0,0,0.4);}.fb_checkbox,.fb_radio{border:none;}input[type="radio"],input[type="submit"]{font-size:108%;padding:4px 8px;-moz-border-radius:5px;-webkit-border-radius:5px;border-radius:5px;cursor:pointer;background-color:#EEE;background:-moz-linear-gradient(top,#FFF 0%,#DFDFDF 40%,#C3C3C3 100%);background:-webkit-gradient(linear, left top, left bottom, from(#FFF), to(#C3C3C3), color-stop(0.4, #DFDFDF));-moz-transition:-moz-box-shadow 0.3s linear;-webkit-transition:-webkit-box-shadow 0.3s linear;text-shadow:0px 1px 1px rgba(255,255,255,0.9);-webkit-box-shadow:0 2px 3px rgba(0,0,0,0.4);-moz-box-shadow:0 2px 3px rgba(0,0,0,0.4);box-shadow:0 2px 3px rgba(0,0,0,0.4);}input:hover[type="submit"]{background:#D0D0D0;color:#0D3247;background:-moz-linear-gradient(top,#FFF,#B0B0B0);background:-webkit-gradient(linear,left top,left bottom,from(#FFF), to(#B0B0B0));-webkit-box-shadow:0 2px 9px rgba(0,0,0,0.4);-moz-box-shadow:0 2px 9px rgba(0,0,0,0.4);box-shadow:0 2px 9px rgba(0,0,0,0.4);}input:active[type="submit"]{background:-webkit-gradient(linear,left top,left bottom,from(#B0B0B0), to(#EEE));background:-moz-linear-gradient(top,#B0B0B0,#EEE);-webkit-box-shadow:0 1px 5px rgba(0,0,0,0.8);-moz-box-shadow:0 1px 5px rgba(0,0,0,0.8);box-shadow:0 1px 5px rgba(0,0,0,0.8);}h1,h2{font-size:350%;padding:15px;text-shadow:0px 1px 2px rgba(0,0,0,0.4);}p{padding:10px 20px;}div{padding:10px 10px 10px 10px;}table{padding:5px 10px;width:100%;}th,td{padding:14px 6px;border-bottom:1px solid #F3F3F3;border-bottom:1px solid rgba(0,0,0,0.025);font-size:85%;}th{color:#666;font-size:108%;font-weight:normal;border:0;background-color:#E0E0E0;background:-moz-linear-gradient(top,rgba(243,243,243,0.5) 0%,rgba(208,208,208,0.9) 80%,rgba(207,207,207,0.9) 100%);background:-webkit-gradient(linear,left top,left bottom,from(rgba(243,243,243,0.5)),to(rgba(207,207,207,0.9)),color-stop(0.8, rgba(208,208,208,0.9)));text-shadow:0px 1px 1px rgba(255,255,255,0.9);}tr{background-color:rgba(255,255,255,0.1);}tr:hover{background-color:rgba(0,0,0,0.025);}div.block{padding:5px;text-align:right;font-size:108%;}.menu{background-color:#E3E3E3;background:-moz-linear-gradient(top,rgba(240,240,240,0.5) 0%,rgba(224,224,224,0.9) 60%,rgba(221,221,221,0.9) 100%);background:-webkit-gradient(linear,left top,left bottom,from(rgba(240,240,240,0.5)),to(rgba(221,221,221,0.9)),color-stop(0.6,rgba(224,224,224,0.9)));padding:0px;width:100%;height:37px;-moz-border-radius-topleft:5px;-moz-border-radius-topright:5px;-webkit-border-top-left-radius:5px;-webkit-border-top-right-radius:5px;border-top-left-radius:5px;border-top-right-radius:5px;}.menu ul{padding:10px 6px 0px 6px;}.menu ul li{display:inline;}.menu ul li a{text-shadow:0px 1px 1px rgba(255,255,255,0.9);float:left;display:block;color:#555;background-color:#D0D0D0;text-decoration:none;margin:0px 4px;padding:6px 18px;height:15px;-moz-border-radius-topleft:5px;-moz-border-radius-topright:5px;-webkit-border-top-left-radius:5px;-webkit-border-top-right-radius:5px;border-top-left-radius:5px;border-top-right-radius:5px;-moz-transition:background-color 0.2s linear;-webkit-transition:background-color 0.2s linear;-o-transition:background-color 0.2s linear;}.menu ul li a:hover,.menu ul li a.current{-webkit-box-shadow:0px -2px 3px rgba(0,0,0,0.07);-moz-box-shadow:0px -2px 3px rgba(0,0,0,0.07);box-shadow:0px -2px 3px rgba(0,0,0,0.07);}.menu ul li a:hover{background-color:#F0F0F0;color:#0D3247;}.menu ul li a:active{background-color:#FFF;color:#1B80BB;}.menu ul li a.current,.menu ul li a.current:hover{cursor:pointer;background-color:#FFF;}.pager{display:block;float:left;padding:2px 6px;border:1px solid #D0D0D0;margin-right:1px;background-color:rgba(255,255,255,0.1);-moz-border-radius:3px;-webkit-border-radius:3px;border-radius:3px;-moz-transition:border 0.2s linear;-webkit-transition:border 0.2s linear;-o-transition:border 0.2s linear;}a.pager:hover{border:1px solid #1B80BB;}</style>', js => '<link rel="stylesheet" href="https://ajax.googleapis.com/ajax/libs/jqueryui/1/themes/smoothness/jquery-ui.css" type="text/css"/><script type="text/javascript" charset="utf-8" src="https://ajax.googleapis.com/ajax/libs/jquery/1/jquery.min.js"></script><script type="text/javascript" charset="utf-8" src="https://ajax.googleapis.com/ajax/libs/jqueryui/1/jquery-ui.min.js"></script><script type="text/javascript" charset="utf-8">$(function(){$(".date").datepicker({ dateFormat: "dd/mm/yy" });});</script>', load_js => undef},
		columns => {
			'integer' => {validate => 'INT', sortopts => 'NUM'},
			'numeric' => {validate => 'NUM', sortopts => 'NUM'},
			'float' => {validate => 'FLOAT', sortopts => 'NUM'},
			'text' => {type => 'textarea', cols => '55', rows => '10'},
			'postcode' => {sortopts => 'NUM', validate => '/^\d{3,4}$/', maxlength => 4},
			'address' => {format => {for_view => sub {_view_address(@_);}}},
			'date' => {class => 'date', validate => '/^(0?[1-9]|[1-2][0-9]|3[0-1])\/(0?[1-9]|1[0-2])\/[0-9]{4}|([0-9]{4}\-0?[1-9]|1[0-2])\-(0?[1-9]|[1-2][0-9]|3[0-1])$/', format => {for_edit => sub {_edit_date(@_);}, for_update => sub {_update_date(@_);}, for_search => sub {_search_date(@_);}, for_filter => sub {_search_date(@_);}, for_view => sub{_view_date(@_);}}},
			'datetime' => {validate => '/^(0?[1-9]|[1-2][0-9]|3[0-1])\/(0?[1-9]|1[0-2])\/[0-9]{4}|([0-9]{4}\-0?[1-9]|1[0-2])\-(0?[1-9]|[1-2][0-9]|3[0-1])\s+[0-9]{1,2}:[0-9]{2}$/', format => {for_edit => sub{_edit_datetime(@_);}, for_view => sub{_view_datetime(@_);}, for_update => sub{_update_datetime(@_);}, for_search => sub {_search_date(@_);}, for_filter => sub {_search_date(@_);}}},
			'timestamp' => {readonly => "readonly", disabled => 1, format => {for_view => sub {_view_timestamp(@_);}, for_create => sub {_create_timestamp(@_);}, for_edit => sub {_create_timestamp(@_);}, for_update => sub {_update_timestamp(@_);}, for_search => sub {_search_timestamp(@_);}, for_filter => sub {_search_timestamp(@_);}}},
			'description' => {sortopts => 'LABELNAME', type => 'textarea', cols => '55', rows => '10'},
			'time' => {validate => '/^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/', maxlength => 5, format => {for_update => sub {_update_time(@_)}, for_edit => sub{_edit_time(@_);}, for_view => sub{_view_time(@_);}}},
			'length' => {validate => 'NUM', sortopts => 'NUM', format => {for_view => sub {my ($self, $column) = @_;my $value = $self->$column;return unless $value;return $value.' cm';}}},
			'weight' => {validate => 'NUM', sortopts => 'NUM', format => {for_view => sub {my ($self, $column) = @_;my $value = $self->$column;return unless $value;return $value.' kg';}}},
			'volume' => {validate => 'NUM', sortopts => 'NUM', format => {for_view => sub {my ($self, $column) = @_;my $value = $self->$column;return unless $value;return $value.' cm<sup>3</sup>';}}},
			'gender' => {options => ['Male', 'Female']},
			'name' => {sortopts => 'LABELNAME', required => 1, stringify => 1},
			'first_name' => {validate => 'FNAME', sortopts => 'LABELNAME', required => 1, stringify => 1},
			'last_name' => {validate => 'LNAME', sortopts => 'LABELNAME', required => 1, stringify => 1},
			'email' => {required => 1, validate => 'EMAIL', sortopts => 'LABELNAME', format => {for_view => sub {my ($self, $column) = @_;my $value = $self->$column;return unless $value;return qq(<a href="mailto:$value">$value</a>);}}},
			'url' => {sortopts => 'LABELNAME', format => {for_view => sub {my ($self, $column) = @_;my $value = $self->$column;return unless $value;return qq(<a href="$value">$value</a>);}}},
			'phone' => {validate => '/^[\+\d\s\-\(\)]+$/'},
			'username' => {validate => '/^[a-zA-Z0-9]{4,}$/', sortopts => 'LABELNAME', required => 1},
			'password' => {validate => '/^[\w.!?@#$%&*]{5,}$/', type => 'password', format => {for_view => sub {return '****';}, for_edit => sub {return;}, for_update => sub {my ($self, $column, $value) = @_;return $self->$column(Digest::MD5::md5_hex($value)) if $value;}}, comment => 'Minimum 5 characters', unsortable => 1},
			'confirm_password' => {required => 1, type => 'password', validate => {javascript => "!= form.elements['password'].value"}},
			'abn' => {label => 'ABN', validate => '/^(\d{2}\s*\d{3}\s*\d{3}\s*\d{3})$/', comment => 'e.g. 12 234 456 678'},
			'money' => {validate => '/^\-?\d{1,11}(\.\d{2})?$/', sortopts => 'NUM', format => {for_view => sub {my ($self, $column) = @_;return unless defined $self->$column;return sprintf ('$%.02f', $self->$column);}, for_edit => sub {my ($self, $column) = @_;return unless defined $self->$column;return sprintf ('%.02f', $self->$column);}}},
			'percentage' => {validate => 'NUM', sortopts => 'NUM', comment => 'e.g.: 99.8', format => {for_view => sub {my ($self, $column, $value) = @_;$value = $self->$column;return unless $value;my $p = $value*100;return "$p%";}, for_edit => sub {my ($self, $column) = @_;my $value = $self->$column;return unless defined $value;return $value*100;}, for_update => sub {my ($self, $column, $value) = @_;return $self->$column($value/100) if $value;},  for_search => sub {_search_percentage(@_);}, for_filter => sub {_search_percentage(@_);}}},
			'document' => {validate => '/^[\w\s.!?@#$\(\)\'\_\-:%&*\/\\\\\[\]]+$/', format => {remove => sub {_remove_file(@_);}, path => sub {_get_file_path(@_);}, url => sub {_get_file_url(@_);}, for_update => sub {_update_file(@_);}, for_view => sub {_view_file(@_)}}, type => 'file'},
			'image' => {validate => '/^[\w\s.!?@#$\(\)\'\_\-:%&*\/\\\\\[\]]+\.(gif|jpg|jpeg|png|GIF|JPG|JPEG|PNG)$/', format => {remove => sub {_remove_file(@_);}, path => sub {_get_file_path(@_);}, url => sub {_get_file_url(@_);}, for_view => sub {_view_image(@_);}, for_update => sub {_update_file(@_);}}, type => 'file'},
			'media' => {validate => '/^[\w\s.!?@#$\(\)\'\_\-:%&*\/\\\\\[\]]+$/', format => {remove => sub {_remove_file(@_);}, path => sub {_get_file_path(@_);}, url => sub {_get_file_url(@_);}, for_view => sub {_view_media(@_);}, for_update => sub {_update_file(@_);}}, type => 'file'},
			'video' => {validate => '/^[\w\s.!?@#$\(\)\'\_\-:%&*\/\\\\\[\]]+$/', format => {remove => sub {_remove_file(@_);}, path => sub {_get_file_path(@_);}, url => sub {_get_file_url(@_);}, for_view => sub {_view_video(@_);}, for_update => sub {_update_file(@_);}}, type => 'file'},
			'audio' => {validate => '/^[\w\s.!?@#$\(\)\'\_\-:%&*\/\\\\\[\]]+$/', format => {remove => sub {_remove_file(@_);}, path => sub {_get_file_path(@_);}, url => sub {_get_file_url(@_);}, for_view => sub {_view_audio(@_);}, for_update => sub {_update_file(@_);}}, type => 'file'},
			'ipv4' => {validate => 'IPV4'},
			'boolean' => {validate => '/^[0-1]$/', sortopts => 'LABELNAME', options => {1 => 'Yes', 0 => 'No'}, format => {for_create => sub {my ($self, $column) = @_;my $default = $self->meta->{columns}->{$column}->{default};return unless length($default);return {'true' => 1, 'false' => 0}->{$default};return $default;}, for_view => sub {my ($self, $column) = @_;my $options = {1 => 'Yes', 0 => 'No'};return $options->{$self->$column};}, for_search => sub {_search_boolean(@_)}, for_filter => sub {_search_boolean(@_)}}},
		}
	};

	$config->{columns}->{'doubleprecision'} = $config->{columns}->{'numeric'};
	$config->{columns}->{'decimal'} = $config->{columns}->{'numeric'};
	$config->{columns}->{'bigint'} = $config->{columns}->{'integer'};
	$config->{columns}->{'serial'} = $config->{columns}->{'integer'};
	$config->{columns}->{'bigserial'} = $config->{columns}->{'integer'};
	$config->{columns}->{'quantity'} = $config->{columns}->{'integer'};
	$config->{columns}->{'height'} = $config->{columns}->{'length'};
	$config->{columns}->{'width'} = $config->{columns}->{'length'};
	$config->{columns}->{'depth'} = $config->{columns}->{'length'};
	$config->{columns}->{'title'} = $config->{columns}->{'name'};
	$config->{columns}->{'birth'} = $config->{columns}->{'date'};
	$config->{columns}->{'mobile'} = $config->{columns}->{'phone'};
	$config->{columns}->{'fax'} = $config->{columns}->{'phone'};
	$config->{columns}->{'cost'} = $config->{columns}->{'money'};
	$config->{columns}->{'price'} = $config->{columns}->{'money'};
	$config->{columns}->{'blob'} = $config->{columns}->{'text'};
	$config->{columns}->{'comment'} = $config->{columns}->{'text'};
	$config->{columns}->{'file'} = $config->{columns}->{'document'};
	$config->{columns}->{'report'} = $config->{columns}->{'document'};
	$config->{columns}->{'photo'} = $config->{columns}->{'image'};
	$config->{columns}->{'logo'} = $config->{columns}->{'image'};
	$config->{columns}->{'sound'} = $config->{columns}->{'audio'};
	$config->{columns}->{'voice'} = $config->{columns}->{'audio'};
	$config->{columns}->{'movie'} = $config->{columns}->{'video'};
	$config->{columns}->{'web'} = $config->{columns}->{'url'};
	return $config;
}

sub config {
	my ($self, $config) = @_;
	unless ($self && defined $self->{CONFIG}) {
		$self->{CONFIG} = _config();
	}

	if ($config) {
		foreach my $hash (keys %{$config}) {
			if ($hash eq 'columns') {
				foreach my $column (keys %{$config->{columns}}) {
					foreach my $key (keys %{$config->{columns}->{$column}}) {
						if ($key eq 'format') {
							foreach my $method (keys %{$config->{columns}->{$column}->{format}}) {
								$self->{CONFIG}->{columns}->{$column}->{format}->{$method} = $config->{columns}->{$column}->{format}->{$method};
							}
						}
						else {
							$self->{CONFIG}->{columns}->{$column}->{$key} = $config->{columns}->{$column}->{$key};
						}
					}
				}
			}
			else {
				foreach my $key (keys %{$config->{$hash}}) {
					$self->{CONFIG}->{$hash}->{$key} = $config->{$hash}->{$key};
				}
			}
		}
	}

	return $self->{CONFIG};
}

sub load {
	my ($self, $args) = @_;
	$args = {} unless ref $args eq 'HASH';
	my $config = $self->config;
	unless (exists $args->{loader} && defined $args->{loader}->{class_prefix}) {
		if (defined $args->{loader}->{base_class}) {
			$args->{loader}->{class_prefix} = $args->{loader}->{base_class};
		}
		elsif (defined $config->{db}->{name}) {
			if ($config->{db}->{type} eq 'SQLite') {
				my ($file, $ext) = ($config->{db}->{name} =~ /.*[\\\/](.*?)(\.[^\.]+)?$/x);
				$args->{loader}->{class_prefix} = ucfirst $file if $file;
			}
			else {
				$args->{loader}->{class_prefix} = $config->{db}->{name};
				$args->{loader}->{class_prefix} =~ s/_(.)/\U$1/gx;
				$args->{loader}->{class_prefix} =~ s/[^\w:]/_/gx;
				$args->{loader}->{class_prefix} =~ s/\b(\w)/\u$1/gx;
			}
		}
	}
	
	my $auto_base = $args->{loader}->{class_prefix} . '::DB::AutoBase1';
	
	return if (defined $config->{db}->{check_class} && "$config->{db}->{check_class}"->isa('Rose::DB::Object')) || $auto_base->isa('Rose::DB');

	unless (defined $args->{loader}->{db} || defined $args->{loader}->{db_class}) {
		unless (defined $args->{loader}->{db_dsn}) {
			my $host;
		 	$host = 'host='. $config->{db}->{host} if $config->{db}->{host};
			$host .= ';port='.$config->{db}->{port} if $config->{db}->{port};
			$args->{loader}->{db_dsn} = qq(dbi:$config->{db}->{type}:dbname=$config->{db}->{name};$host);
		}

		$args->{loader}->{db_options}->{AutoCommit} ||= 1;
		$args->{loader}->{db_options}->{ChopBlanks} ||= 1;
		$args->{loader}->{db_username} ||= $config->{db}->{username};
		$args->{loader}->{db_password} ||= $config->{db}->{password};
	}

	my $loader = Rose::DB::Object::Loader->new(%{$args->{loader}});
	$loader->convention_manager->tables_are_singular(1) if $config->{db}->{tables_are_singular};

	my $sorted_column_definition_keys = [sort { length $b <=> length $a } keys %{$config->{columns}}];
	my @loaded = $loader->make_classes(%{$args->{make_classes}});
	no strict 'refs';
	foreach my $class (@loaded) {
		my $class_type;
	
		if (($class)->isa('Rose::DB::Object')) {			
			if ($auto_base->isa('Rose::DB') && ! (defined $args->{loader}->{db_class} || defined $args->{loader}->{base_class} || defined $args->{loader}->{base_classes}) && $config->{db}->{new_or_cached}) {
				my $package_init_db = $class . '::init_db';
				*$package_init_db = sub {
					$auto_base->new_or_cached;
				};
			}
			
			_process_columns($class, $config, $sorted_column_definition_keys);
			my $package_renderer_config = $class . '::renderer_config';
			*$package_renderer_config = sub {return $config};

			$class_type = 'object';
		}
		else {
			$class_type = 'manager';
		}
		
		foreach my $sub (@{$EXPORT_TAGS{$class_type}}) {
			my $package_sub = $class . '::' . $sub;
			*$package_sub = \&$sub;
		}
	}
	
	return wantarray ? @loaded : \@loaded;
}

sub _process_columns {
    my @args = @_;
	my ($class, $config, $sorted_column_definition_keys) = _class_config_column_keys(@args);
	my ($custom_definitions, $validated_unique_keys);
	my $foreign_keys = _get_foreign_keys($class);
	my $unique_keys = _get_unique_keys($class);
	my $package = '';
	foreach my $column (@{$class->meta->columns}) {
		my $column_type;
		unless ($column->{is_primary_key_member}) {
			if (exists $config->{columns}->{$column} && ! exists $custom_definitions->{$column}) {
				$column_type = $column;
				if (exists $foreign_keys->{$column}) {
					my $foreign_object_name = $foreign_keys->{$column}->{name};
					$config->{columns}->{$column}->{label} = _label($foreign_object_name) unless exists $config->{columns}->{$column}->{label};
					$config->{columns}->{$column}->{required} = 1 unless exists $config->{columns}->{$column}->{required};
					$config->{columns}->{$column}->{validate} = 'INT' unless exists $config->{columns}->{$column}->{validate};
					$config->{columns}->{$column}->{format}->{for_view} = sub {
						my ($self, $column) = @_;
						return unless $self->$column;
						return $self->$foreign_object_name->stringify_me;
					} unless exists $config->{columns}->{$column}->{format} && exists $config->{columns}->{$column}->{format}->{for_view};
				}
			}
			elsif (exists $foreign_keys->{$column}) {
				my $foreign_object_name = $foreign_keys->{$column}->{name};
				$config->{columns}->{$column} = {
					label => _label(_title($foreign_object_name, $config->{db}->{table_prefix})), 
					required => 1, 
					validate => 'INT', 
					sortopts => 'LABELNAME', format => {
						for_view => sub {
							my ($self, $column) = @_;
							return unless $self->$column;
							return $self->$foreign_object_name->stringify_me if $self->can($foreign_object_name); # handle foreign key like columns
							return $self->$column;
						}
					}
				};
				$column_type = $column;
			}
			else {
				DEF: foreach my $column_key (@{$sorted_column_definition_keys}) {
					if ($column =~ /$column_key/x && ! exists $custom_definitions->{$column_key}) {
						$column_type = $column_key;
						last DEF;
					}
				}

				unless (defined $column_type) {
					my $rdbo_column_type = lc ref $class->meta->{columns}->{$column};
					($rdbo_column_type) = $rdbo_column_type =~ /^.*::([\w_]+)$/x;

					if (exists $config->{columns}->{$rdbo_column_type}) {
						$column_type = $rdbo_column_type;
					}
					else {
						my $custom_definition;
						$custom_definition->{required} = 1 if $class->meta->{columns}->{$column}->{not_null};
						$custom_definition->{maxlength} = $class->meta->{columns}->{$column}->{length} if defined $class->meta->{columns}->{$column}->{length};

						if (defined $class->meta->{columns}->{$column}->{check_in}) {
							$custom_definition->{options} = $class->meta->{columns}->{$column}->{check_in};
							$custom_definition->{multiple} = 1 if ref $class->meta->{columns}->{$column} eq 'Rose::DB::Object::Metadata::Column::Set';
						}

						$config->{columns}->{$column} = $custom_definition;
						$column_type = $column;
						$custom_definitions->{$column} = undef;
					}
				}
			}

			if (exists $unique_keys->{$column}) {
				unless ($column eq $column_type) {
					foreach my $key (keys %{$config->{columns}->{$column_type}}) {
						$config->{columns}->{$column}->{$key} = $config->{columns}->{$column_type}->{$key};
					}
				}
                
                my ($column_config, $column_type_config); 
                
                if (exists $config->{columns}->{$column}) {
                    $column_config = $config->{columns}->{$column};
                    Scalar::Util::weaken($column_config);
                }
                
                if (exists $config->{columns}->{$column_type}) {
                    $column_type_config = $config->{columns}->{$column_type};
                    Scalar::Util::weaken($column_type_config);
                }
                                        
				if (exists $column_type_config->{validate}) {
					if (ref $column_type_config->{validate} eq 'HASH') {
						$validated_unique_keys->{$column} = $column_type_config->{validate}->{javascript};
					}
					else {
						if (ref $validated_unique_keys->{$column} eq 'CODE') {
							$validated_unique_keys->{$column} = undef;
						}
						else {
							if (ref $validated_unique_keys->{$column} eq 'ARRAY') {
								$validated_unique_keys->{$column} = $column_type_config->{validate};
                                
								$config->{columns}->{$column}->{validate} = {
									javascript => $validated_unique_keys->{$column},
									perl => sub {my ($value, $form) = @_;return unless length($value);my $found;foreach my $v (@{$validated_unique_keys->{$column}}){if($value eq $v){$found = 1;last;}};return if ! $found;return _unique($column_config, $class, $column, $value, $form);}
								};
							}
							else {
								if (exists $CGI::FormBuilder::Field::VALIDATE{$column_type_config->{validate}}) {
									$validated_unique_keys->{$column} =  $CGI::FormBuilder::Field::VALIDATE{$column_type_config->{validate}};
								}
								else {
									$validated_unique_keys->{$column} = $column_type_config->{validate};
								}

								if ($validated_unique_keys->{$column} =~ /^m(\S)(.*)\1$/ || $validated_unique_keys->{$column} =~ /^(\/)(.*)\1$/) {
									(my $regex = $2) =~ s#\\/#/#gx;
								    $regex =~ s#/#\\/#gx;
									$config->{columns}->{$column}->{validate} = {
										javascript => $validated_unique_keys->{$column},
										perl => sub {my ($value, $form) = @_;return if ! length($value) || ! ($value =~ /$regex/);return _unique($column_config, $class, $column, $value, $form);}
									};
								}
								else {
									$config->{columns}->{$column}->{validate} = {
										javascript => $validated_unique_keys->{$column},
										perl => sub {my ($value, $form) = @_;return if $value ne $validated_unique_keys->{$column};return _unique($column_config, $class, $column, $value, $form);}
									};
								}
							}
						}
					}
				}
				else {
					$validated_unique_keys->{$column} = undef;
					$config->{columns}->{$column}->{validate} = sub {my ($value, $form) = @_;return unless length($value);return _unique($column_config, $class, $column, $value, $form);};
				}

				$column_type = $column;
				$config->{columns}->{$column}->{required} = 1 unless exists $config->{columns}->{$column}->{required};

				unless (defined $config->{columns}->{$column}->{message}) {
					my $column_label;
					if (defined $config->{columns}->{$column}->{label}) {
						$column_label = $config->{columns}->{$column}->{label};
					}
					else {
						$column_label = _label($column);
					}
					$config->{columns}->{$column}->{message} = qq($column_label already exists or is invalid, please choose another one.);

					unless (defined $config->{columns}->{$column}->{jsmessage}) {
						if (exists $foreign_keys->{$column}) {
							$config->{columns}->{$column}->{jsmessage} = qq(- Choose one of the "$column_label" options);
						}
						else {
							$config->{columns}->{$column}->{jsmessage} = qq(- Invalid entry for the "$column_label" field);
						}
					}
				}
			}
			elsif (exists $validated_unique_keys->{$column_type} && $column ne $column_type) {
				# prevent inheriting validation subref from matching unique column type
				foreach my $key (keys %{$config->{columns}->{$column_type}}) {
					$config->{columns}->{$column}->{$key} = $config->{columns}->{$column_type}->{$key};
				}
				$config->{columns}->{$column}->{validate} = $validated_unique_keys->{$column_type};
				delete $config->{columns}->{$column}->{message};
				delete $config->{columns}->{$column}->{jsmessage};
				$column_type = $column;
			}

			_generate_methods($class, $config, $column, $column_type);
		}
	}
	return $package;
}

sub prepare_renderer {
    my @args = @_;
	my ($class, $config, $sorted_column_definition_keys) = _class_config_column_keys(@args);
	_process_columns($class, $config, $sorted_column_definition_keys);
	no strict 'refs';
	my $package_renderer_config = $class . '::renderer_config';
	*$package_renderer_config = sub {return $config};
	return $config;
}

sub _class_config_column_keys {
	my $class = shift;
	my $config = shift || _config();
	my $sorted_column_definition_keys = shift || [sort { length $b <=> length $a } keys %{$config->{columns}}];
	return ($class, $config, $sorted_column_definition_keys);
}

sub _generate_methods {
	my ($class, $config, $column, $column_type) = @_;
	no strict 'refs';
	if (exists $config->{columns}->{$column_type}->{format}) {
		foreach my $custom_method_key (keys %{$config->{columns}->{$column_type}->{format}}) {
			unless ($class->can($column . '_' . $custom_method_key)) {
				my $package_custom_method = $class . '::' . $column . '_' . $custom_method_key;
				my $format_sub = $config->{columns}->{$column_type}->{format}->{$custom_method_key};
				*$package_custom_method = sub {
					my ($self, $value) = @_;
					return $format_sub->($self, $column, $value);
				};
			}
		}
	}
	
	unless ($class->can($column . '_' . 'definition')) {
		my $package_column_definition = $class . '::' . $column . '_definition';
		*$package_column_definition = sub {return $config->{columns}->{$column_type};};
	}
	return;
}

sub _before {
	my ($self, $weak_args) = @_;
	my $before = delete $weak_args->{before};
	Scalar::Util::weaken($weak_args);
	return $before->($self, $weak_args);
}

sub render_as_form {
	my ($self, %args) = @_;
	_before($self, \%args) if exists $args{before};
	my ($class, $form_action, $field_order, $output, $relationship_object);
	my $table = $self->meta->table;
	my $form_title = $args{title};
	$class = ref $self || $self;
	my $renderer_config = _prepare($class, $args{renderer_config}, $args{prepared});
	my ($ui_type) = (caller(0))[3] =~ /^.*_(\w+)$/x;
	my $form_config = _ui_config($ui_type, $renderer_config, \%args);
	
	my $form_id = _identify($class, $args{prefix}, $ui_type);
	my $field_prefix = '';
	$field_prefix = $form_id . '_' if defined $args{prefix};
	
	if (ref $self) {
		if ($args{copy}) {
			$form_action = 'copy';
		}
		else {
			$form_action = 'update';
			(my $action_object_prefix = $form_id) =~ s/_form$//x;
			
			unless (exists $args{queries} && $args{queries}->{$action_object_prefix . '_action'}) {
				my $primary_key = $class->meta->primary_key_column_names->[0];
				$args{queries}->{action} ||= 'edit';
				$args{queries}->{object} ||= $self->$primary_key;
			}
		}
		$form_title ||= _label($form_action . ' ' . $self->stringify_me(prepared => $args{prepared}));
	}
	else {
		$form_action = 'create';
		$form_title ||= _label($form_action . ' ' . _singularise_table(_title($table, $renderer_config->{db}->{table_prefix}), $renderer_config->{db}->{tables_are_singular}));
	}

	my $cancel = $form_config->{cancel};
	my $template_url = $args{template_url} || $renderer_config->{template}->{url};
	my $template_path = $args{template_path} || $renderer_config->{template}->{path};
	my $html_head = _html_head(\%args, $renderer_config);

	my $foreign_keys = _get_foreign_keys($class);
	my $relationships = _get_relationships($class);
	my $column_order = $args{order} || _get_column_order($class, $relationships);

	my $form_template;
	if ($args{template} eq 1) {
		$form_template = $ui_type . '.tt';
	}
	else {
		$form_template = $args{template};
	}

	my $form_def = $args{form};
	$form_def->{name} ||= $form_id;
	$form_def->{enctype} ||= 'multipart/form-data';
	$form_def->{method} ||= 'post';
	$form_def->{params} ||= $args{query};
	$form_def->{stylesheet} = 1 unless exists $form_def->{stylesheet};
	$form_def->{action} ||= $form_config->{action} if $form_config->{action};

	if($args{template}) {
		$form_def->{jserror} ||= 'notify_error';
	}
	else {
		$form_def->{messages}->{form_required_text} = '';
	}

	$form_def->{jsfunc} ||= qq(if (form._submit.value == '$cancel' || form.$form_id\_submit_cancel.value == 1) {return true;});

	my $form = CGI::FormBuilder->new($form_def);

	foreach my $column (@{$column_order}) {
		my $field_def;
		$field_def = $args{fields}->{$column} if exists $args{fields} && exists $args{fields}->{$column};
				
		my $column_definition_method = $column . '_definition';
		if ($class->can($column_definition_method)) {
			my $column_definition = $class->$column_definition_method;
			foreach my $property (keys %{$column_definition}) {
				$field_def->{$property} = $column_definition->{$property} unless defined $field_def->{$property} || $property eq 'format'  || $property eq 'stringify' || $property eq 'unsortable';
			}
		}
		
		if (exists $relationships->{$column}) {
			# one to many or many to many relationships
			$field_def->{validate} ||= 'INT';
			$field_def->{sortopts} ||= 'LABELNAME';
			$field_def->{multiple} ||= 1;

			my $foreign_class_primary_key = $relationships->{$column}->{class}->meta->primary_key_column_names->[0];

			if (ref $self && ! exists $field_def->{value}) {
				my $foreign_object_value;

			 	foreach my $foreign_object ($self->$column) {
					$foreign_object_value->{$foreign_object->$foreign_class_primary_key} = $foreign_object->stringify_me(prepared => $args{prepared});
					$relationship_object->{$column}->{$foreign_object->$foreign_class_primary_key} = undef; # keep it for update
				}
				$field_def->{value} = $foreign_object_value;
			}

			unless ($field_def->{static} || (defined $field_def->{type} && $field_def->{type} eq 'hidden') || exists $field_def->{options}) {
				my $objects = Rose::DB::Object::Manager->get_objects(object_class => $relationships->{$column}->{class});
				if (@{$objects}) {
					foreach my $object (@{$objects}) {
						$field_def->{options}->{$object->$foreign_class_primary_key} = $object->stringify_me(prepared => $args{prepared});
					}
				}
				else {
					$field_def->{type} ||= 'select';
					$field_def->{disabled} ||= 1;
					$field_def->{options} = ['']; # bypass CGI::FormBuilder warning
				}
			}
		}
		elsif (exists $class->meta->{columns}->{$column}) {
			# normal column
			$field_def->{required} = 1 if ! defined $field_def->{required} && $class->meta->{columns}->{$column}->{not_null};
			
			unless (exists $field_def->{options} || (defined $field_def->{type} && $field_def->{type} eq 'hidden')) {
				if (exists $foreign_keys->{$column}) {
					# create or edit
					my $foreign_class = $foreign_keys->{$column}->{class};
					my $foreign_class_primary_key = $foreign_class->meta->primary_key_column_names->[0];
					if ($field_def->{static}) {
						if (ref $self) {
							if ($self->$column) {
								my $foreign_column = $foreign_keys->{$column}->{name};
								$field_def->{options} = {$self->$column => $self->$foreign_column->stringify_me(prepared => $args{prepared})};
							}
						}
						else {
							my $foreign_object_id;
							if (defined $field_def->{value}) {
								$foreign_object_id = $field_def->{value};
							}
							elsif(defined $self->meta->{columns}->{$column}->{default}) {
								$foreign_object_id = $self->meta->{columns}->{$column}->{default};
							}

							if ($foreign_object_id) {
								my $foreign_object = $foreign_class->new($foreign_class_primary_key => $foreign_object_id);
								$field_def->{options} = {$foreign_object_id => $foreign_object->stringify_me(prepared => $args{prepared})} if $foreign_object->load(speculative => 1);
							}
						}
					}
					else {
						my $objects = Rose::DB::Object::Manager->get_objects(object_class => $foreign_keys->{$column}->{class});
						if (@{$objects}) {
							foreach my $object (@{$objects}) {
								$field_def->{options}->{$object->$foreign_class_primary_key} = $object->stringify_me(prepared => $args{prepared});
							}
						}
						else {
							$field_def->{type} ||= 'select';
							$field_def->{disabled} ||= 1;
							$field_def->{options} = ['']; # bypass CGI::FormBuilder warning
						}
					}
				}
				elsif (exists $class->meta->{columns}->{$column}->{check_in}) {
					$field_def->{options} = $class->meta->{columns}->{$column}->{check_in};
					$field_def->{multiple} = 1 if ! exists $field_def->{multiple} && ref $class->meta->{columns}->{$column} eq 'Rose::DB::Object::Metadata::Column::Set';
				}
				elsif (! exists $field_def->{type} && ref $class->meta->{columns}->{$column} eq 'Rose::DB::Object::Metadata::Column::Text') {
					$field_def->{type} = 'textarea';
					$field_def->{cols} ||= '55';
					$field_def->{rows} ||= '10';
				}
			}

			if (ref $self) {
				# edit
				unless (exists $field_def->{value}) {
					my $current_value;
					if ($class->can($column . '_for_edit')) {
						my $edit_method = $column . '_for_edit';
						$current_value = $self->$edit_method;
						if (ref $current_value eq 'ARRAY' || ref $current_value eq 'HASH') {
							$field_def->{value} = $current_value;
						}
						else {
							$field_def->{value} = "$current_value"; # make object stringifies
						}
					}
					else {
						if (ref $self->meta->{columns}->{$column} eq 'Rose::DB::Object::Metadata::Column::Set') {
							$field_def->{value} = $self->$column;
						}
						elsif (exists $field_def->{multiple} && $field_def->{multiple} && $field_def->{options}) {
							my $delimiter = '\\' . $form_config->{delimiter};
							$field_def->{value} = [split /$delimiter/, $self->$column];
						}
						else {
							$current_value = $self->$column;
							$field_def->{value} = "$current_value"; # double quote to make it literal to stringify object refs such as DateTime
						}

						if (exists $field_def->{other} && $field_def->{other} && $field_def->{options}) {
							if (ref $field_def->{options} eq 'HASH') {
								if (ref $field_def->{value} eq 'ARRAY') {
									foreach my $value (@{$field_def->{value}}) {
										$field_def->{options}->{$value} = $value unless exists $field_def->{options}->{$value};
									}
								}
								else {
									$field_def->{options}->{$field_def->{value}} = $field_def->{value} unless exists $field_def->{options}->{$field_def->{value}};
								}
							}
							else {
								# must be array
								my $available_options;
								foreach my $option (@{$field_def->{options}}) {
									$available_options->{$option} = undef;
								}

								if (ref $field_def->{value} eq 'ARRAY') {
									foreach my $value (@{$field_def->{value}}) {
										push @{$field_def->{options}}, $value unless exists $available_options->{$value};
									}
								}
								else {
									push @{$field_def->{options}}, $field_def->{value} unless exists $available_options->{$field_def->{value}};
								}
							}
						}
					}
				}

				if ($field_def->{type} eq 'file') {
					# file: if value exist in db, or in cgi param when the same form reloads
					delete $field_def->{value};
					unless (exists $field_def->{comment}) {
						my $value = $form->cgi_param($form_id.'_'.$column) || $form->cgi_param($column) || $self->$column;
						my $file_location = _get_file_url($self, $column, $value);
						
						if ($file_location) {
							$field_def->{comment} = '<a class="button" href="'.$file_location.'">'. $form_config->{download_message} .'</a>';
							if ($form_config->{remove_files}) {
								my $remove_field_id = 'remove_'. $field_prefix . $column;
								$field_def->{comment} .= ' <input id="'. $remove_field_id . '" name="'. $field_prefix . 'remove_files" type="checkbox" value="' . $column . '"/><label for="' . $remove_field_id . '">' . $form_config->{remove_message} . '</label>';
							}
						}
					}
				}
			}
			else {
				unless (exists $field_def->{value}) {
					if ($class->can($column . '_for_create')) {
						my $create_method = $column.'_for_create';
						my $create_result = $self->$create_method($self->meta->{columns}->{$column}->{default});
						$field_def->{value} = $create_result if defined $create_result;
					}
					else {
						$field_def->{value} = $self->meta->{columns}->{$column}->{default} if defined $self->meta->{columns}->{$column}->{default};
					}
				}
			}
		}

		delete $field_def->{value} if $field_def->{multiple} && $form->submitted && ! $form->cgi_param($column) && ! $form->cgi_param($form_id.'_'.$column);

		$field_def->{label} ||= _label(_title($column, $renderer_config->{db}->{table_prefix}));

		unless (exists $field_def->{name}) {
			push @{$field_order}, $field_prefix . $column;
			$field_def->{name} = $field_prefix . $column;
		}
		$form->field(%{$field_def});
	}

	foreach my $query_key (keys %{$args{queries}}) {
		$form->field(name => $query_key, value => $args{queries}->{$query_key}, type => 'hidden', force => 1);
	}

	$form->field(name => $form_id . '_submit_cancel', type => 'hidden', force => 1);

	unless (defined $args{controller_order}) {
		foreach my $controller (keys %{$args{controllers}}) {
			push @{$args{controller_order}}, $controller;
		}

		push @{$args{controller_order}}, ucfirst ($form_action) unless $args{controllers} && exists $args{controllers}->{ucfirst ($form_action)};
		push @{$args{controller_order}}, $cancel unless $args{controllers} && exists $args{controllers}->{$cancel};
	}

	$form->{submit} = $args{controller_order};
	$args{template_data} ||= {};
	
	if ($args{template}) {
		my $template_options = $args{template_options} || $renderer_config->{template}->{options};
		$template_options->{INCLUDE_PATH} ||= $template_path;
			
		$form->template({
			variable => 'form', 
			data => {
				template_url => $template_url,
				field_order => $field_order,
				form_id => $form_id,
				form_submit => _touch_up($form->prepare->{submit}, $cancel, $form_id),
				title => $form_title,
				description => $args{description},
				doctype => $renderer_config->{misc}->{doctype},
				html_head => $html_head,
				no_head => $args{no_head},
				self => $self,
				cancel => $cancel,
				extra => $args{extra},
				%{$args{template_data}}
			},
			template => $form_template, 
			engine => $template_options, 
			type => 'TT2'
		});
	}

	if ($form->submitted) {
		if ($form->submitted ne $cancel) {
			my $form_validate = $form->validate(%{$args{validate}});
			if ($form_validate) {
				my $form_action_callback = '_'.$form_action.'_object';
				my @files_to_remove;
				@files_to_remove = $form->cgi_param($field_prefix . 'remove_files') if $form_config->{remove_files};
				
				if (exists $args{controllers}->{$form->submitted}) {
					# method buttons
					if (ref $args{controllers}->{$form->submitted} eq 'HASH') {
						if ($args{controllers}->{$form->submitted}->{$form_action}) {
							unless (ref $args{controllers}->{$form->submitted}->{$form_action} eq 'CODE' && ! $args{controllers}->{$form->submitted}->{$form_action}->($self)) {
							    no strict 'refs';
								$self = $form_action_callback->($self, $class, $table, $field_order, $form, $form_id, $args{prefix}, $relationships, $relationship_object, \@files_to_remove);
								$output->{self} = $self;
							}
						}

						$output->{controller} = $args{controllers}->{$form->submitted}->{callback}->($self) if ref $args{controllers}->{$form->submitted}->{callback} eq 'CODE';

						$args{hide_form} = 1 if exists $args{controllers}->{$form->submitted}->{hide_form};
					}
					else {
						$output->{controller} = $args{controllers}->{$form->submitted}->($self) if ref $args{controllers}->{$form->submitted} eq 'CODE';
					}
				}
				elsif($form->submitted eq ucfirst ($form_action)) {
				    no strict 'refs';
					$self = $form_action_callback->($self, $class, $table, $field_order, $form, $form_id, $args{prefix}, $relationships, $relationship_object, \@files_to_remove);
					$output->{self} = $self;
				}
				$output->{validate} = $form_validate;
			}
		}
		else {
			$output->{validate} = 1;
		}
	}

	my ($hide_form, $html_form);
	$hide_form = $form_id.'_' if $args{prefix};
	$hide_form .= 'hide_form';

	$args{hide_form} = 1 if $form->cgi_param($hide_form);
	unless ($args{hide_form}) {
		if ($args{template}) {
			$html_form .= $form->render;
		}
		else {
			$html_form .= qq(<div><h1>$form_title</h1>);
			$html_form .= qq(<p>$args{description}</p>) if defined $args{description};
			$html_form .= _touch_up($form->render(), $cancel, $form_id) . '</div>';
			
			$html_form = qq($renderer_config->{misc}->{doctype}<html><head><title>$form_title</title>$html_head</head><body>$html_form</body></html>) unless $args{no_head};
		}

		$args{output}?$output->{output} = $html_form:print $html_form;
	}

	return $output;
}

sub render_as_table {
	my ($self, %args) = @_;
	_before($self, \%args) if exists $args{before};
	my ($table, @controllers, $output, $query_hidden_fields, $q, $sort_by_column);
	my $class = $self->object_class();
	my $query = $args{query} || CGI->new;
	my $url = $args{url} || $query->url(-absolute => 1);
	my $renderer_config = _prepare($class, $args{renderer_config}, $args{prepared});
	my ($ui_type) = (caller(0))[3] =~ /^.*_(\w+)$/x;
	my $table_config = _ui_config($ui_type, $renderer_config, \%args);

	my $table_id = _identify($class, $args{prefix}, $ui_type);
	my $table_title = $args{title} || _label(_pluralise_table(_title($class->meta->table, $renderer_config->{db}->{table_prefix}), $renderer_config->{db}->{tables_are_singular}));

	my $like_operator = $table_config->{like_operator} || ($class->meta->db->driver eq 'pg'?'ilike':'like');
	my $template_url = $args{template_url} || $renderer_config->{template}->{url};
	my $template_path = $args{template_path} || $renderer_config->{template}->{path};
	my $html_head = _html_head(\%args, $renderer_config);

	my $primary_key = $class->meta->primary_key_column_names->[0];
	my $relationships = _get_relationships($class);
	my $column_order = $args{order} || _get_column_order($class, $relationships);
	my $foreign_keys = _get_foreign_keys($class);

	my ($objects, $previous_page, $next_page, $last_page, $total);

	my $param_list = {'sort_by' => 'sort_by', 'per_page' => 'per_page', 'page' => 'page', 'q' => 'q', 'ajax' => 'ajax', 'action' => 'action', 'object' => 'object', 'hide_table' => 'hide_table'};

	if ($args{prefix}) {
		foreach my $param (keys %{$param_list}) {
			$param_list->{$param} = $table_id.'_'.$param;
		}
	}

	if ($args{objects}) {
		$objects = $args{objects};
		$table_config->{no_pagination} = 1;
	}
	elsif ($args{get_from_sql}) {
		if (ref $args{get_from_sql} eq 'HASH') {
			$objects = $self->get_objects_from_sql(%{$args{get_from_sql}});
		}
		else {
			$objects = $self->get_objects_from_sql($args{get_from_sql});
		}
		$table_config->{no_pagination} = 1;
	}
	else {
		my $sort_by = $query->param($param_list->{'sort_by'});
		if ($sort_by) {
			$sort_by_column = $sort_by;
			$sort_by_column =~ s/\sdesc$//x;
			my $sort_by_column_definition_method = $sort_by_column . '_definition';
			my $sort_by_column_definition;
			$sort_by_column_definition = $class->$sort_by_column_definition_method if $class->can($sort_by_column_definition_method);

			unless (! exists $class->meta->{columns}->{$sort_by_column} || (defined $sort_by_column_definition && $sort_by_column_definition->{unsortable}) || (exists $args{columns} && exists $args{columns}->{$sort_by_column} && (exists $args{columns}->{$sort_by_column}->{value} || $args{columns}->{$sort_by_column}->{unsortable}))) {
				if ($sort_by_column eq $primary_key) {
					$args{get}->{sort_by} = 't1.' . $sort_by;
				}
				else {
					$args{get}->{sort_by} = 't1.' . $sort_by . ', '. $class->meta->table . '.' . $primary_key; # append an unique column to the sort by clause to prevent inconsistent results using LIMIT and OFFSET in PostgreSQL
				}
			}
		}
		else {
			$args{get}->{sort_by} ||= $primary_key; # always sort by primary key by default to prevent inconsistent results using LIMIT and OFFSET in PostgreSQL
		}

		if ($args{searchable}) {
			$query_hidden_fields = _create_hidden_field($args{queries}); # this has to be done before appending 'q' to $args{queries}, which get serialised later as query stings

			if (defined $args{q}) {
				$q = $args{q};
			}
			else {
				$q = $query->param($param_list->{'q'});
			}

			if (length $q) {
				my ($or, @raw_qs, @qs);
				my $keyword_delimiter = $table_config->{keyword_delimiter};
				if ($keyword_delimiter) {
					@raw_qs = split /$keyword_delimiter/, $q;
				}
				else {
					@raw_qs = $q;
				}

				my $like_search_values;
				foreach my $raw_q (@raw_qs) {
					$raw_q =~ s/^\s+|\s+$//gx;
					push @qs, $raw_q;
					push @{$like_search_values}, '%' . $raw_q . '%';
				}

				my $table_alias = {$class => 't1'};
				my $table_to_class;
				if ($class->meta->db->driver eq 'pg' && $args{get}) {
					my $counter = 1;
					($table_alias, $table_to_class) = _alias_table($args{get}->{with_objects}, $class, \$counter, $table_alias, $table_to_class) if $args{get}->{with_objects};
					($table_alias, $table_to_class) = _alias_table($args{get}->{require_objects}, $class, \$counter, $table_alias, $table_to_class) if $args{get}->{require_objects};
				}
				
				my $searchable_columns;
				ref $args{searchable} eq 'ARRAY' ? ($searchable_columns = $args{searchable}) : ($searchable_columns = $class->meta->column_names);
				
				foreach my $searchable_column (@{$searchable_columns}) {
					my ($search_values, $search_class, $search_column, $search_method);
					if ($searchable_column =~ /\./x) {
						my $search_table;
						($search_table, $search_column) = split /\./x, $searchable_column;
						$search_class = $table_to_class->{$search_table} || $class;
					}
					else {
						$search_class = $class;
						$search_column = $searchable_column;
					}

					if ($search_class->can($search_column . '_for_search')) {
						$search_method = $search_column.'_for_search';
						foreach my $q (@qs) {
							my $search_result = $search_class->$search_method($q);
							push @{$search_values}, '%' . $search_result . '%' if defined $search_result;
						}
					}
					else {
						$search_values = $like_search_values;
					}

					if ($search_class && $search_class->meta->db->driver eq 'pg' && exists $search_class->meta->{columns}->{$search_column} && ! $search_class->meta->{columns}->{$search_column}->isa('Rose::DB::Object::Metadata::Column::Character')) {
						my $searchable_column_text = 'text(' . $table_alias->{$search_class} . '.' . $search_column . ') ' . $like_operator . ' ?';
						foreach my $search_value (@{$search_values}) {
							push @{$or}, [\$searchable_column_text => $search_value];
						}
					}
					elsif ($search_class && $search_class->meta->db->driver eq 'sqlite' && exists $search_class->meta->{columns}->{$search_column} && ! $search_class->meta->{columns}->{$search_column}->isa('Rose::DB::Object::Metadata::Column::Character')) {
						my $searchable_column_text = 'cast(' . $table_alias->{$search_class} . '.' . $search_column . ' AS TEXT) ' . $like_operator . ' ?';
						foreach my $search_value (@{$search_values}) {
							push @{$or}, [\$searchable_column_text => $search_value];
						}
					}
					else {
						push @{$or}, $searchable_column => {$like_operator => $search_values};
					}
				}

				push @{$args{get}->{query}}, 'or' => $or;

				$args{queries}->{$param_list->{q}} = $q;

				$table_title = $args{search_result_title} || $table_config->{search_result_title};
				$table_title =~ s/\[%\s*q\s*%\]/$q/x;
			}
		}

		my $filtered_columns;
		my $filterable = $args{filterable} || $column_order;
		foreach my $column (@{$filterable}) {
			unless (exists $relationships->{$column}) {
				my $cgi_column;
				$cgi_column = $table_id.'_' if $args{prefix};
				$cgi_column .= $column;
				
				my $cgi_column_param = $query->param($cgi_column);
				if (defined $cgi_column_param && length $cgi_column_param) {
					my @cgi_column_values = $query->param($cgi_column);
					my $formatted_values;
					if ($class->can($column . '_for_filter')) {
						my $filter_method = $column . '_for_filter';
						foreach my $cgi_column_value (@cgi_column_values) {
							my $filter_result = $class->$filter_method($cgi_column_value);
							push @{$formatted_values}, $filter_result if $filter_result;
						}
					}
					elsif ($class->can($column)) {
						$formatted_values = \@cgi_column_values;
					}

					if ($formatted_values) {

						if ($table_config->{like_filter}) {

							my $formatted_values_like = [map {'%' . $_ . '%'} @{$formatted_values}];
							
							if ($class && $class->meta->db->driver eq 'pg' && exists $class->meta->{columns}->{$column} && ! $class->meta->{columns}->{$column}->isa('Rose::DB::Object::Metadata::Column::Character')) {
								my $filter_column_text = 'text(t1.' . $column . ') ' . $like_operator . ' ?';
								push @{$filtered_columns}, \$filter_column_text => $formatted_values_like;
							}
							elsif ($class && $class->meta->db->driver eq 'sqlite' && exists $class->meta->{columns}->{$column} && ! $class->meta->{columns}->{$column}->isa('Rose::DB::Object::Metadata::Column::Character')) {
								my $filter_column_text = 'cast(t1.' . $column . ' AS TEXT) ' . $like_operator . ' ?';
								push @{$filtered_columns}, \$filter_column_text => $formatted_values_like;
							}
							else {
								push @{$filtered_columns}, $column => {$like_operator => $formatted_values_like};
							}

						}
						else {
							push @{$filtered_columns}, $column => $formatted_values;	
						}

						$args{queries}->{$cgi_column} = \@cgi_column_values unless exists $args{queries}->{$cgi_column};
					}
				}
			}
		}

		if ($filtered_columns) {
			if($table_config->{or_filter}) {
				push @{$args{get}->{query}}, 'or' => $filtered_columns;
			}
			else {
				foreach my $filtered_column (@{$filtered_columns}) {
					push @{$args{get}->{query}}, $filtered_column; 
				}
			}
		}

		unless (exists $args{get} && (exists $args{get}->{limit} || exists $args{get}->{offset})) {
			my $query_param_per_page = $query->param($param_list->{'per_page'});
			$args{get}->{per_page} ||= $query_param_per_page || $table_config->{per_page};
			$args{queries}->{$param_list->{per_page}} ||= $query_param_per_page if $query_param_per_page;
			$args{get}->{page} ||= $query->param($param_list->{'page'}) || 1;
		}
		$objects = $self->get_objects(%{$args{get}});
		$output->{objects} = $objects;

		## Handle Submission
		my $reload_object;
		if ($query->param($param_list->{action})) {
			my $valid_form_actions = {create => undef, edit => undef, copy => undef};
			my $action = $query->param($param_list->{action});

			if (exists $valid_form_actions->{$action} && $args{$action}) {
				$args{$action} = {} if $args{$action} == 1;
				$args{$action}->{output} = 1;
				
				$args{$action}->{no_head} = $args{no_head} if exists $args{no_head} && ! exists $args{$action}->{no_head};
				$args{$action}->{prepared} = $args{prepared} if exists $args{prepared} && ! exists $args{$action}->{prepared};
				
				_cascade($table_config->{cascade}, \%args, $args{$action});
				
				foreach my $option (@{$table_config->{form_options}}) {
					_inherit_form_option($option, $action, \%args);
				}
								
				$args{$action}->{order} ||= Clone::clone($args{order}) if $args{order};
				$args{$action}->{template} ||= _template($args{template}, 'form', 1) if $args{template};
				
				@{$args{$action}->{queries}}{keys %{$args{queries}}} = values %{$args{queries}};
				$args{$action}->{queries}->{$param_list->{action}} = $action;
				$args{$action}->{queries}->{$param_list->{sort_by}} = $query->param($param_list->{sort_by}) if $query->param($param_list->{sort_by});
				$args{$action}->{queries}->{$param_list->{page}} = $query->param($param_list->{page}) if $query->param($param_list->{page});
				$args{$action}->{prefix} ||= $table_id.'_form';

				my $form;
				if ($action eq 'create') {
					$form = $class->render_as_form(%{$args{$action}});
				}
				elsif ($query->param($param_list->{object})) {
					$args{$action}->{queries}->{$param_list->{object}} = $query->param($param_list->{object});

				    $args{$action}->{copy} = 1 if $action eq 'copy';

					foreach my $object (@{$objects}) {
						if ($object->$primary_key eq $query->param($param_list->{object})) {
							$form = $object->render_as_form(%{$args{$action}});
							$output->{form} = $form;
							last;
						}
					}
				}

				$form->{validate}?$reload_object = 1:$output->{output} = $form->{output};
			}
			elsif ($query->param($param_list->{object})) {
				$reload_object = 1;
				my @object_ids = $query->param($param_list->{object});
				my (%valid_object_ids, @action_objects);
				@valid_object_ids{@object_ids} = ();

				foreach my $object (@{$objects}) {
					push @action_objects, $object if exists $valid_object_ids{$object->$primary_key};
				}

				if ($query->param($param_list->{action}) eq 'delete' && $args{delete}) {
					foreach my $action_object (@action_objects) {
						$action_object->delete_with_file;
					}
				}
				elsif (exists $args{controllers} && exists $args{controllers}->{$query->param($param_list->{action})}) {
					no strict 'refs';
					foreach my $action_object (@action_objects) {
						if (ref $args{controllers}->{$query->param($param_list->{action})} eq 'HASH') {
							$output->{controller} = $args{controllers}->{$query->param($param_list->{action})}->{callback}->($action_object) if ref $args{controllers}->{$query->param($param_list->{action})}->{callback} eq 'CODE';
							$args{hide_table} = 1 if exists $args{controllers}->{$query->param($param_list->{action})}->{hide_table};
						}
						else {
							$output->{controller} = $args{controllers}->{$query->param($param_list->{action})}->($action_object) if ref $args{controllers}->{$query->param($param_list->{action})} eq 'CODE';
						}
					}
				}
			}

			if(defined $output->{output}) {
				return $output if $args{output};
				print $output->{output};
				return;
			}
		}

		($previous_page, $next_page, $last_page, $total) = _pagination($self, $class, $args{get}) unless $table_config->{no_pagination};

		if($reload_object) {
			$args{get}->{page} = $last_page if $args{get}->{page} > $last_page;
			$objects = $self->get_objects(%{$args{get}});
			$output->{objects} = $objects;
		}
	}


	## Render Table

	$args{hide_table} = 1 if $query->param($param_list->{'hide_table'});
	unless ($args{hide_table}) {
		my ($html_table, $query_string);
		if ($args{controller_order}) {
		 	@controllers = @{$args{controller_order}};
		}
		else {
		 	@controllers = keys %{$args{controllers}} if $args{controllers};
			foreach my $form_action ('copy', 'edit', 'delete') {
				push @controllers, $form_action if $args{$form_action} && ! exists $args{controllers}->{$form_action};
			}
		}

		$args{queries}->{$param_list->{ajax}} = 1 if $args{ajax} && $args{template};
		
		my $default_query_string = '';
		$default_query_string = _create_query_string($args{queries}) if exists $args{queries};
		$query_string->{base} = $default_query_string;
		$query_string->{sort_by} = $default_query_string;
		$query_string->{page} = $default_query_string;

		if($query->param($param_list->{sort_by})) {
			$query_string->{page} .= $param_list->{sort_by}.'='.$query->param($param_list->{sort_by}).'&amp;' unless $query_string->{page} =~ /$param_list->{sort_by}=/x;
			$query_string->{exclusive} = $param_list->{sort_by}.'='.$query->param($param_list->{sort_by}).'&amp;';
		}

		$query_string->{complete} = $query_string->{page};

		if ($query->param($param_list->{page})) {
			$query_string->{complete} .= $param_list->{page}.'='.$args{get}->{page}.'&amp;' unless $query_string->{complete} =~ /$param_list->{page}=/x;
			$query_string->{exclusive} .= $param_list->{page}.'='.$args{get}->{page}.'&amp;';
		}

		## Define Table

		if ($args{create}) {
			if ($args{controllers} && $args{controllers}->{create} && ref $args{controllers}->{create} eq 'HASH' && exists $args{controllers}->{create}->{label}) {
				$table->{create}->{value} = $args{controllers}->{create}->{label};
			}
			elsif (ref $args{create} eq 'HASH' && exists $args{create}->{title}) {
				$table->{create}->{value} = $args{create}->{title};
			}
			else {
				$table->{create}->{value} = 'Create';
			}
			$table->{create}->{link} = qq($url?$query_string->{complete}$param_list->{action}=create);
		}

		$table->{total_columns} = scalar @{$column_order} + scalar @controllers;

		foreach my $column (@{$column_order}) {
			my $head;
			$head->{name} = $column;

			my $column_definition_method = $column . '_definition';
			my $column_definition;
			$column_definition = $class->$column_definition_method if $class->can($column_definition_method);

			if (exists $args{columns} && exists $args{columns}->{$column} && exists $args{columns}->{$column}->{label}) {
				$head->{value} = $args{columns}->{$column}->{label};
			}
			else {
				$head->{value} = $column_definition->{label} || _label(_title($column, $renderer_config->{db}->{table_prefix}));
			}

			unless (exists $relationships->{$column} || $column_definition->{unsortable} || (exists $args{columns} && exists $args{columns}->{$column} && (exists $args{columns}->{$column}->{value} || $args{columns}->{$column}->{unsortable}))) {
				my $sort_by_param = $query->param($param_list->{'sort_by'});
				if (defined $sort_by_param && $sort_by_param eq $column) {
					$head->{link} = qq($url?$query_string->{sort_by}$param_list->{sort_by}=$column desc);
				}
				else {
					$head->{link} = qq($url?$query_string->{sort_by}$param_list->{sort_by}=$column);
				}
			}

			push @{$table->{head}}, $head;
		}

		foreach my $controller (@controllers) {
			my $label;
			if (ref $args{controllers}->{$controller} eq 'HASH' && exists $args{controllers}->{$controller}->{label}) {
				$label = $args{controllers}->{$controller}->{label};
			}
			else {
				$label = _label($controller);
			}
			push @{$table->{head}}, {name => $controller, value => $label, controller => 1};
		}

		foreach my $object (@{$objects}) {
			my $row;
			$row->{object} = $object;
			my $object_id = $object->$primary_key;
			foreach my $column (@{$column_order}) {
				my $value;
				if(exists $args{columns} && exists $args{columns}->{$column} && exists $args{columns}->{$column}->{value}) {
					$value = $args{columns}->{$column}->{value}->{$object_id} if exists $args{columns}->{$column}->{value}->{$object_id};
				}
				elsif(exists $args{columns} && exists $args{columns}->{$column} && exists $args{columns}->{$column}->{accessor}) {
					my $accessor = $args{columns}->{$column}->{accessor};
					$value = $object->$accessor($column) if $object->can($accessor);
				}
				elsif (exists $relationships->{$column}) {
					$value = join $table_config->{delimiter}, map {$_->stringify_me(prepared => $args{prepared})} $object->$column;
				}
				else {
					my $view_method;
					if ($class->can($column . '_for_view')) {
						$view_method = $column . '_for_view';
					}
					elsif ($class->can($column)) {
						$view_method = $column;
					}

					if ($view_method) {
						if (ref $class->meta->{columns}->{$column} eq 'Rose::DB::Object::Metadata::Column::Set') {
							$value = join $table_config->{delimiter}, $object->$view_method;
						}
						else {
							$value = $object->$view_method;
						}
					}

				}
				 
				push @{$row->{columns}}, {name => $column, value => $value};
			}

			foreach my $controller (@controllers) {
				my $label;
				if (ref $args{controllers}->{$controller} eq 'HASH' && exists $args{controllers}->{$controller}->{label}) {
					$label = $args{controllers}->{$controller}->{label};
				}
				else {
					$label = _label($controller);
				}
				my $controller_query_string;
				if (ref $args{controllers}->{$controller} eq 'HASH' && exists $args{controllers}->{$controller}->{queries}) {
					$controller_query_string = $query_string->{exclusive};
					$controller_query_string .= _create_query_string($args{controllers}->{$controller}->{queries});
				}
				else {
					$controller_query_string = $query_string->{complete};
				}
				push @{$row->{columns}}, {name => $controller, value => $label, link => qq($url?$controller_query_string$param_list->{action}=$controller&amp;$param_list->{object}=$object_id), controller => 1};
			}
			push @{$table->{rows}}, $row;
		}

		unless ($table_config->{no_pagination}) {
			$table->{pager}->{first_page} = {value => 1, link => qq($url?$query_string->{page}$param_list->{page}=1)};
			$table->{pager}->{previous_page} = {value => $previous_page, link => qq($url?$query_string->{page}$param_list->{page}=$previous_page)};
			$table->{pager}->{next_page} = {value => $next_page, link => qq($url?$query_string->{page}$param_list->{page}=$next_page)};
			$table->{pager}->{last_page} = {value => $last_page, link => qq($url?$query_string->{page}$param_list->{page}=$last_page)};
			$table->{pager}->{current_page} = {value => $args{get}->{page}, link => qq($url?$query_string->{page}$param_list->{page}=$args{get}->{page})};
			$table->{pager}->{total} = $total;

			if ($table_config->{pages} % 2) {
				$table->{pager}->{start_page} = $table->{pager}->{current_page}->{value} - ($table_config->{pages} - 1)/2;
			}
			else {
				$table->{pager}->{start_page} = $table->{pager}->{current_page}->{value} - $table_config->{pages}/2;
			}

			if ($table->{pager}->{start_page} < 1) {
				$table->{pager}->{start_page} = 1;
			}
			elsif ($table->{pager}->{last_page}->{value} >= $table_config->{pages} && $table->{pager}->{start_page} > $table->{pager}->{last_page}->{value} - $table_config->{pages}) {
				$table->{pager}->{start_page} = $table->{pager}->{last_page}->{value} - $table_config->{pages} + 1;
			}

			if ($table->{pager}->{last_page}->{value} < $table->{pager}->{start_page} + $table_config->{pages}) {
				$table->{pager}->{end_page} = $table->{pager}->{last_page}->{value} + 1;
			}
			else {
				$table->{pager}->{end_page} = $table->{pager}->{start_page} + $table_config->{pages};
			}
		}

		if ($args{template}) {
			my ($template, $ajax);
			if($args{ajax}) {
				$template = $args{ajax_template} || $ui_type . '_ajax.tt';
				$ajax = 1 if $query->param($param_list->{ajax});
			}
			else {
				$template = _template($args{template}, $ui_type);
			}

			$args{template_data} ||= {};
			my $template_options = $args{template_options} || $renderer_config->{template}->{options};
			$html_table = _render_template(options => $template_options, template_path => $template_path, file => $template, output => 1, data => {
				template_url => $template_url,
				ajax => $ajax,
				url => $url,
				query_string => $query_string,
				query_hidden_fields => $query_hidden_fields,
				q => $q,
				param_list => $param_list,
				sort_by_column => $sort_by_column,
				searchable => $args{searchable},
				table => $table,
				objects => $objects,
				column_order => $column_order,
				table_id => $table_id,
				title => $table_title,
				description => $args{description},
				doctype => $renderer_config->{misc}->{doctype},
				html_head => $html_head,
				no_head => $args{no_head},
				no_pagination => $table_config->{no_pagination},
				extra => $args{extra},
				%{$args{template_data}}
			});
		}
		else {
			$html_table .= '<div>';
			$html_table .= qq(<div class="block"><form action="$url" method="get" id="$table_id\_search_form"><input type="text" name="$param_list->{q}" id="$table_id\_search" value="$q" placeholder="Search"/>$query_hidden_fields</form></div>) if $args{searchable};
			$html_table .= qq(<h1>$table_title</h1>);
			$html_table .= qq(<p>$args{description}</p>) if defined $args{description};
			$html_table .= qq(<div class="block"><div><a href="$table->{create}->{link}" class="button">$table->{create}->{value}</a></div></div>) if exists $table->{create};
			$html_table .= qq(<table id="$table_id">);

			$html_table .= '<tr>';
			foreach my $head (@{$table->{head}}) {
				if (exists $head->{link}) {
					$html_table .= qq(<th><a href="$head->{link}">$head->{value}</a></th>);
				}
				elsif (exists $head->{controller}) {
					$html_table .= qq(<th></th>);
				}
				else {
					$html_table .= qq(<th>$head->{value}</th>);
				}
			}
			$html_table .= '</tr>';

			if($table->{rows}) {
				foreach my $row (@{$table->{rows}}) {
					$html_table .= '<tr>';
					foreach my $column (@{$row->{columns}}) {
						if (exists $column->{link}) {
							my $css_class;
							if (exists $column->{controller}) {
								my $css_delete_class = '';
								$css_delete_class = ' delete' if $column->{name} eq 'delete';
								$css_class = ' class="button' . $css_delete_class . '"';
							}
							$html_table .= qq(<td><a href="$column->{link}"$css_class>$column->{value}</a></td>);
						}
						else {
							my $column_value = '';
							$column_value = $column->{value} if defined $column->{value};
							$html_table .= qq(<td>$column_value</td>);
						}

					}
					$html_table .= '</tr>';
				}
			}
			else {
				$html_table .= qq(<tr><td colspan="$table->{total_columns}">$table_config->{empty_message}</td></tr>);
			}

			$html_table .= '</table>';

			unless ($table_config->{no_pagination}) {
				$html_table .= '<div>';
				if ($table->{pager}->{current_page}->{value} eq $table->{pager}->{first_page}->{value}) {
					$html_table .= qq(<span class="pager">&laquo;</span><span class="pager">&lsaquo;</span>);
				}
				else {
					$html_table .= qq(<a href="$table->{pager}->{first_page}->{link}" class="pager">&laquo;</a>);
					$html_table .= qq(<a href="$table->{pager}->{previous_page}->{link}" class="pager">&lsaquo;</a>);
				}

				while ($table->{pager}->{start_page} < $table->{pager}->{end_page}) {
					if ($table->{pager}->{start_page} == $table->{pager}->{current_page}->{value}) {
						$html_table .= qq(<span class="pager">$table->{pager}->{start_page}</span>);
					}
					else {
						$html_table .= qq(<a href="$url?$query_string->{page}$param_list->{page}=$table->{pager}->{start_page}" class="pager">$table->{pager}->{start_page}</a>);
					}
					$table->{pager}->{start_page}++;
				}

				if ($table->{pager}->{current_page}->{value} eq $table->{pager}->{last_page}->{value}) {
					$html_table .= qq(<span class="pager">&rsaquo;</span><span class="pager">&raquo;</span>);
				}
				else {
					$html_table .= qq(<a href="$table->{pager}->{next_page}->{link}" class="pager">&rsaquo;</a>);
					$html_table .= qq(<a href="$table->{pager}->{last_page}->{link}" class="pager">&raquo;</a>);
				}
				$html_table .= '</div>';
			}

			$html_table .= '</div>'; 
			$html_table = qq($renderer_config->{misc}->{doctype}<html><head><title>$table_title</title>$html_head</head><body>$html_table</body></html>) unless $args{no_head};


		}

		$args{output}?$output->{output} = $html_table:print $html_table;
	}

	return $output;
}

sub render_as_menu {
	my ($self, %args) = @_;
	_before($self, \%args) if exists $args{before};
	
	my($menu, $hide_menu_param, $current_param, $output, $item_order, $items, $current, $template);
	my $class = $self->object_class();
	my $renderer_config = _prepare($class, $args{renderer_config}, $args{prepared});
	my ($ui_type) = (caller(0))[3] =~ /^.*_(\w+)$/x;
	my $menu_config = _ui_config($ui_type, $renderer_config, \%args);
	
	my $menu_id = _identify($class, $args{prefix}, $ui_type);
	my $menu_title = $args{title};
	my $template_url = $args{template_url} || $renderer_config->{template}->{url};
	my $template_path = $args{template_path} || $renderer_config->{template}->{path};

	if ($args{prefix}) {
		$hide_menu_param = $menu_id.'_hide_menu';
		$current_param = $menu_id.'_current';
	}
	else {
		$hide_menu_param='hide_menu';
		$current_param = 'current';
	}

	my $query = $args{query} || CGI->new;
	my $url = $args{url} || $query->url(-absolute => 1);
	my $query_string = join ('&amp;', map {"$_=$args{queries}->{$_}"} keys %{$args{queries}});
	$query_string .= '&amp;' if $query_string;

	$template = _template($args{template}, $ui_type) if $args{template};

	$current = $query->param($current_param);
	unless ($current) {
		if ($args{current}) {
			$current = $args{current}->meta->table;
		}
		else {
			$current = $class->meta->table;
		}
	}

	$item_order = $args{order} || [$class];
	$args{template_data} ||= {};

	foreach my $item (@{$item_order}) {
		my $table = $item->meta->table;
		$items->{$item}->{table} = $table;

		if (defined $args{items} && defined $args{items}->{$item} && defined $args{items}->{$item}->{title}) {
			$items->{$item}->{label} = $args{items}->{$item}->{title};
		}
		else {
			$items->{$item}->{label} = _label(_pluralise_table(_title($table, $renderer_config->{db}->{table_prefix}), $renderer_config->{db}->{tables_are_singular}));
		}

		$items->{$item}->{link} = qq($url?$query_string$current_param=$table);
		if ($table eq $current) {
			my $options;
			$options = $args{items}->{$item} if exists $args{items} && exists $args{items}->{$item};
			$options->{output} = 1;

			@{$options->{queries}}{keys %{$args{queries}}} = values %{$args{queries}};
			$options->{queries}->{$current_param} = $table;
			$options->{prefix} ||= $menu_id.'_table';
			$options->{url} ||= $url;

			$options->{template_data} = $args{template_data} unless exists $options->{template_data};

			if ($args{ajax}) {
				my $valid_form_actions = {create => undef, edit => undef, copy => undef};
				$args{hide_menu} = 1 if $query->param($options->{prefix}.'_ajax') && ! exists $valid_form_actions->{$query->param($options->{prefix}.'_action')};
			}

			if ($args{template} && ! exists $options->{template}) {
				if (ref $args{template} eq 'HASH') {
					$options->{template} = $args{template};
				}
				else {
					$options->{template} = 1;
				}
			}
			
			_cascade($menu_config->{cascade}, \%args, $options);
			
			foreach my $shortcut (@{$menu_config->{shortcuts}}) {
				$options->{$shortcut} = 1 if $args{$shortcut} && ! exists $options->{$shortcut};
			}
			
			$options->{no_head} = 1;
			$output->{table} = "$item\::Manager"->render_as_table(%{$options});
			$menu_title ||= $items->{$item}->{label};
		}
	}

	$args{hide_menu} = 1 if $query->param($hide_menu_param);

	my $html_head = _html_head(\%args, $renderer_config);

	if ($args{template}) {
		my $template_options = $args{template_options} || $renderer_config->{template}->{options};
	 	$menu = _render_template(
			options => $template_options,
			template_path => $template_path,
			file => $template, 
			output => 1,
			data => {
				menu_id => $menu_id,
				no_head => $args{no_head},
				doctype => $renderer_config->{misc}->{doctype},
				html_head => $html_head,
				template_url => $template_url, 
				items => $items,
				item_order => $item_order, 
				current => $current,
				title => $menu_title,
				description => $args{'description'},
				content => $output->{table}->{output},
				hide => $args{hide_menu},
				extra => $args{extra},
				%{$args{template_data}}
			}
		);
	}
	else {
		unless ($args{hide_menu}) {
			$menu = '<div><div class="menu"><ul>';
			foreach my $item (@{$item_order}) {
				$menu .= '<li><a ';
				$menu .= 'class="current" ' if $items->{$item}->{table} eq $current;
				$menu .= 'href="'.$items->{$item}->{link}.'">'.$items->{$item}->{label}.'</a></li>';
			}
			$menu .= '</ul></div>';
			$menu .= qq(<p>$args{description}</p>) if defined $args{description};
			$menu .= '</div>';
		}
		$menu .= $output->{table}->{output};
		$menu = qq($renderer_config->{misc}->{doctype}<html><head><title>$menu_title</title>$html_head</head><body>$menu</body></html>) unless $args{no_head};
	}

	$args{output}?$output->{output} = $menu:print $menu;
	return $output;
}

sub render_as_chart {
	my ($self, %args) = @_;
	_before($self, \%args) if exists $args{before};
	my $class = $self->object_class();
	my $renderer_config = _prepare($class, $args{renderer_config}, $args{prepared});
	
	my $title = $args{title} || _label(_pluralise_table(_title($class->meta->table, $renderer_config->{db}->{table_prefix}), $renderer_config->{db}->{tables_are_singular}));
	my $template_url = $args{template_url} || $renderer_config->{template}->{url};
	my $template_path = $args{template_path} || $renderer_config->{template}->{path};
	my $html_head = _html_head(\%args, $renderer_config);
	my ($ui_type) = (caller(0))[3] =~ /^.*_(\w+)$/x;
	my $chart_id = _identify($class, $args{prefix}, $ui_type);

	my $hide_chart_param;
	if ($args{prefix}) {
		$hide_chart_param = $chart_id . '_hide_chart';
	}
	else {
		$hide_chart_param = 'hide_chart';
	}

	my $query = $args{query} || CGI->new;
	$args{hide_chart} ||= $query->param($hide_chart_param);

	return $args{output}?{}:undef if $args{hide_chart};

	my ($chart, $output, $template);
	if (ref $args{engine} eq 'CODE') {
		no strict 'refs';
		$chart = $args{engine}->($self, %args);
	}
	else {
		$args{options}->{chs} ||= $args{size} || '600x300';
		$args{options}->{chco} ||= 'ff6600';

		if (exists $args{type}) {
			my $type = {
				pie => 'p',
				bar => 'bvg',
				line => 'ls'
			};

			if (exists $type->{$args{type}}) {
				$args{options}->{cht} ||= $type->{$args{type}};

				unless (exists $args{options}->{chd}) {
					my (@values, @labels);
					if ($args{type} eq 'pie' && $args{column}) {
						my $column = $args{column};
						my $filtered_values;
						if ($args{values}) {
							foreach my $value (@{$args{values}}) {
								$filtered_values->{$value} = undef;
							}
						}

						my $foreign_keys = _get_foreign_keys($class);
						my ($foreign_class, $foreign_class_primary_key);
						if (exists $foreign_keys->{$args{column}}) {
							$foreign_class = $foreign_keys->{$args{column}}->{class};
							$foreign_class_primary_key = $foreign_class->meta->primary_key_column_names->[0];
						}

						my $primary_key = $class->meta->primary_key_column_names->[0]; # borrow the primary key column
						foreach my $object (@{$self->get_objects_from_sql(sql => 'SELECT ' . $column . ', COUNT('. $column .') AS ' . $primary_key . ' FROM ' . $class->meta->table . ' GROUP BY ' . $column . ' ORDER BY '. $column)}) {
							if (! $filtered_values || exists $filtered_values->{$object->$column}) {
								push @values, $object->$primary_key;

								if (exists $foreign_keys->{$args{column}}) {
									my $foreign_object = $foreign_class->new($foreign_class_primary_key => $object->$column);

									if($foreign_object->load(speculative => 1)) {
										push @labels, $foreign_object->stringify_me(prepared => $args{prepared});
									}
								}
								else {
									push @labels, $object->$column;
								}
							}
						}

						$args{options}->{chd} = 't:' . join (',', @values);
					}
					elsif ($args{objects} && $args{columns}) {
						my $min = 0;
						my $max = 0;

						$args{options}->{chxt} ||= 'x,y';
						$args{options}->{chdl} ||= join ('|', @{$args{columns}});

						my $objects = $self->get_objects(query => [id => $args{objects}]);
						@labels = map {$_->stringify_me(prepared => $args{prepared})} @{$objects};

						foreach my $column (@{$args{columns}}) {
							my @object_values;
							foreach my $object (@{$objects}) {
								if ($object->$column) {
									push (@object_values, $object->$column);

									if ($object->$column > $max) {
										$max = $object->$column;
									}
									elsif($object->$column < $min) {
										$min = $object->$column;
									}
								}
								else {
									push (@object_values, 0);
								}
							}
							push (@values, join (',', @object_values));
						}

						$args{options}->{chd} = 't:' . join ('|', @values);

						$args{options}->{chds} ||= $min . ',' . $max;
						unless (exists $args{options}->{chxl} || ($max <= 100 && $min >= 0)) {
							my $avg = ($max - abs($min)) / 2;
							my $max_avg = ($max - abs($avg)) / 2 + $avg;
							my $min_avg = ($avg - abs($min)) / 2;

							$args{options}->{chxl} = '1:|' . join ('|', ($min, $min_avg, $avg, $max_avg, $max));
						}
					}

					$args{options}->{chl} = join ('|', @labels);
				}
			}
		}

		my $chart_url = 'http://chart.apis.google.com/chart?' . _create_query_string($args{options});

		if ($args{template}) {
			if($args{template} == 1) {
				$template = $ui_type . '.tt';
			}
			else {
				$template = $args{template};
			}

			$args{template_data} ||= {};
			
			my $template_options = $args{template_options} || $renderer_config->{template}->{options};
			$chart = _render_template(
				options => $template_options,
				template_path => $template_path,
				file => $template,
				output => 1,
				data => {
					template_url => $template_url,
					chart => $chart_url,
					options => $args{'options'},
					chart_id => $chart_id,
					title => $title ,
					description => $args{'description'},
					no_head => $args{no_head},
					doctype => $renderer_config->{misc}->{doctype},
					html_head => $html_head,
					extra => $args{extra},
					%{$args{template_data}}
				}
			);
		}
		else {
			$chart = qq(<div><h1>$title</h1>);
			$chart .= qq(<p>$args{description}</p>) if defined $args{description};
			$chart .= qq(<img src="$chart_url" alt="$title"/></div>);
			$chart = qq($renderer_config->{misc}->{doctype}<html><head><title>$title</title>$html_head</head><body>$chart</body></html>) unless $args{no_head};
		}
	}

	$args{output}?$output->{output} = $chart:print $chart;
	return $output;
}

sub _render_template {
	my %args = @_;
	if ($args{file} && $args{data} && $args{template_path}) {
		my $options = $args{options};
		$options->{INCLUDE_PATH} ||= $args{template_path};
		my $template = Template->new(%{$options});
		if($args{output}) {
			my $output = '';
			$template->process($args{file},$args{data}, \$output) || die $template->error(), "\n";
			return $output;
		}
		else {
			return $template->process($args{file},$args{data});
		}
	}
}

# util

sub _cascade {
	my ($cascade, $args, $options) = @_;
	foreach my $option (@{$cascade}) {
		$options->{$option} = $args->{$option} if defined $args->{$option} && ! defined $options->{$option};
	}
	return;
}

sub _ui_config {
	my ($ui_type, $renderer_config, $args) = @_;
	my $ui_config;
	foreach my $option (keys %{$renderer_config->{$ui_type}}) {
		if (defined $args->{$option}) {
			$ui_config->{$option} = $args->{$option};
		}
		else {
			$ui_config->{$option} = $renderer_config->{$ui_type}->{$option};
		}
	}
	return $ui_config;
}

sub _prepare {
	my ($class, $config, $prepared) = @_;
	return $class->prepare_renderer($config) unless $prepared || $class->can('renderer_config');
	return $config || $class->renderer_config();
}

sub _get_renderer_config {
	my $self = shift;
	return $self->renderer_config() if $self->can('renderer_config');
	return _config();
}

sub _pagination {
	my ($self, $class, $get) = @_;
	my $total = $self->get_objects_count(%{$get});
	return (1, 1, 1, $total) unless $get->{per_page} && $get->{page};
	my ($last_page, $next_page, $previous_page);
	if ($total < $get->{per_page}) {
		$last_page = 1;
	}
	else {
		my $pages = $total / $get->{per_page};
		if ($pages == int $pages) {
			$last_page = $pages;
		}
		else {
			$last_page = 1 + int($pages);
		}
	}

	if ($get->{page} == $last_page) {
		$next_page = $last_page;
	}
	else {
		$next_page = $get->{page} + 1;
	}

	if ($get->{page} == 1) {
		$previous_page = 1;
	}
	else {
		$previous_page = $get->{page} - 1;
	}

	return ($previous_page, $next_page, $last_page, $total);
}

sub _copy_object {
	my ($self, $class, $table, $field_order, $form, $form_id, $prefix, $relationships, $relationship_object, $files_to_remove) = @_;
	my $clone = Rose::DB::Object::Helpers::clone_and_reset($self);
	$clone->save(); # need the auto generated primary key for files;

	my $renderer_config = _get_renderer_config($self);
	my $primary_key = $self->meta->primary_key_column_names->[0];
	my $self_upload_path = File::Spec->catdir($renderer_config->{upload}->{path}, $self->stringify_class, $self->$primary_key);
	File::Copy::Recursive::dircopy($self_upload_path, File::Spec->catdir($renderer_config->{upload}->{path}, $self->stringify_class, $clone->$primary_key)) if -d $self_upload_path;

	return _update_object($clone, $class, $table, $field_order, $form, $form_id, $prefix, $relationships, $relationship_object, $files_to_remove);
}

sub _update_object {
	my ($self, $class, $table, $field_order, $form, $form_id, $prefix, $relationships, $relationship_object, $files_to_remove) = @_;
	my $primary_key = $self->meta->primary_key_column_names->[0];

	foreach my $field (@{$field_order}) {
		my $column = $field;
		$column =~ s/$form_id\_//x if $prefix;
		my $field_value;
		my @values = $form->field($field);
		my $values_size = scalar @values;

		if($values_size > 1) {
			$field_value = join _get_renderer_config($self)->{form}->{delimiter}, @values;
		}
		else {
			$field_value = $form->field($field); # if this line is removed, $form->field function will still think it should return an array, which will fail for file upload
		}

		if (exists $relationships->{$column}) {
			my $foreign_class = $relationships->{$column}->{class};
			my $foreign_class_foreign_keys = _get_foreign_keys($foreign_class);
			my $foreign_key;

			foreach my $fk (keys %{$foreign_class_foreign_keys}) {
				if ($foreign_class_foreign_keys->{$fk}->{class} eq $class) {
					$foreign_key = $fk;
					last;
				}
			}

			my $default = undef;
			$default = $relationships->{$column}->{class}->meta->{columns}->{$table.'_id'}->{default} if defined $relationships->{$column}->{class}->meta->{columns}->{$table.'_id'}->{default};
			 # $form->field($field) won't work
			if(length($form->cgi_param($field))) {
				my ($new_foreign_object_id, $old_foreign_object_id, $value_hash, $new_foreign_object_id_hash);
				my $foreign_class_primary_key = $relationships->{$column}->{class}->meta->primary_key_column_names->[0];

				foreach my $id (@values) {
					push @{$new_foreign_object_id}, $foreign_class_primary_key => $id;
					$value_hash->{$id} = undef;
					push @{$new_foreign_object_id_hash}, {$foreign_class_primary_key => $id};
				}

				foreach my $id (keys %{$relationship_object->{$column}}) {
					push @{$old_foreign_object_id}, $foreign_class_primary_key => $id unless exists $value_hash->{$id};
				}

				if ($relationships->{$column}->{type} eq 'one to many') {
					Rose::DB::Object::Manager->update_objects(object_class => $foreign_class, set => {$foreign_key => $default}, where => [or => $old_foreign_object_id]) if $old_foreign_object_id;
					Rose::DB::Object::Manager->update_objects(object_class => $foreign_class, set => {$foreign_key => $self->$primary_key}, where => [or => $new_foreign_object_id]) if $new_foreign_object_id;
				}
				else {
					 # many to many
					$self->$column(@{$new_foreign_object_id_hash});
				}
			}
			else {
				if ($relationships->{$column}->{type} eq 'one to many') {
					Rose::DB::Object::Manager->update_objects(object_class => $foreign_class, set => {$foreign_key => $default}, where => [$foreign_key => $self->$primary_key]);
				}
				else {
					# many to many
					$self->$column([]); # cascade deletes foreign objects
				}
			}
		}
		else {
			my $update_method;
			if ($class->can($column . '_for_update')) {
				$update_method = $column . '_for_update';
			}
			elsif ($class->can($column)) {
				$update_method = $column;
			}

			if ($update_method) {
				if (length($form->cgi_param($field))) {
					$self->$update_method($field_value);
				}
				else {
					$self->$update_method(undef);
				}
			}
		}
	}
	
	_remove_column_files($self, $files_to_remove) if $files_to_remove && @{$files_to_remove};
	$self->save;
	return $self;
}

sub _create_object {
	my ($self, $class, $table, $field_order, $form, $form_id, $prefix, $relationships, $relationship_object, $files_to_remove) = @_;
	my $custom_field_value;

	$self = $self->new();

	foreach my $field (@{$field_order}) {
		if(defined $form->cgi_param($field) && length($form->cgi_param($field))) {
			my $column = $field;
			$column =~ s/$form_id\_//x if $prefix;
			my @values = $form->field($field);
			 # one to many or many to many
			if (exists $relationships->{$column}) {
				my $new_foreign_object_id_hash;
				my $foreign_class_primary_key = $relationships->{$column}->{class}->meta->primary_key_column_names->[0];

				foreach my $id (@values) {
					push @{$new_foreign_object_id_hash}, {$foreign_class_primary_key => $id};
				}

				$self->$column(@{$new_foreign_object_id_hash});
			}
			else {
				my $field_value;
				my $values_size = scalar @values;
				if($values_size > 1) {
					$field_value = join _get_renderer_config($self)->{form}->{delimiter}, @values;
				}
				else {
					$field_value = $form->field($field); # if this line is removed, $form->field function will still think it should return an array, which will fail for file upload
				}

				if ($class->can($column . '_for_update')) {
					$custom_field_value->{$column . '_for_update'} = $field_value; # save it for later
					$self->$column('0') if $self->meta->{columns}->{$column}->{not_null}; # zero fill not null columns
				}
				elsif ($class->can($column)) {
					$self->$column($field_value);
				}
			}
		}
	}

	$self->save;

	# after save, run formatting methods, which may require an id, such as file upload
	if ($custom_field_value) {
		foreach my $update_method (keys %{$custom_field_value}) {
			$self->$update_method($custom_field_value->{$update_method});
		}
		$self->save;
	}

	return $self;
}

sub _get_column_order {
	my ($class, $relationships) = @_;
	my $order;
	foreach my $column (sort {$a->ordinal_position <=> $b->ordinal_position} @{$class->meta->columns}) {
		push @{$order}, "$column" unless exists $column->{is_primary_key_member};
	}

	foreach my $relationship (keys %{$relationships}) {
		push @{$order}, $relationship;
	}
	return $order;
}

sub _get_foreign_keys {
	my $class = shift;
	my $foreign_keys;
	foreach my $foreign_key (@{$class->meta->foreign_keys}) {
		(my $key, my $value) = $foreign_key->_key_columns;
		$foreign_keys->{$key} = {name => $foreign_key->name, table => $foreign_key->class->meta->table, column => $value, is_required => $foreign_key->is_required, class => $foreign_key->class};
	}
	return $foreign_keys;
}

sub _get_unique_keys {
	my $class = shift;
	my $unique_keys;
	foreach my $unique_key (@{$class->meta->{unique_keys}}) {
		$unique_keys->{$unique_key->columns->[0]} = undef;
	}
	return $unique_keys;
}

sub _get_relationships {
	my $class = shift;
	my $relationships;

	foreach my $relationship (@{$class->meta->relationships}) {
		if ($relationship->type eq 'one to many') {
			$relationships->{$relationship->name}->{type} = $relationship->type;
			$relationships->{$relationship->name}->{class} = $relationship->class;
		}
		elsif($relationship->type eq 'many to many') {
			$relationships->{$relationship->name}->{type} = $relationship->type;
			$relationships->{$relationship->name}->{class} = $relationship->foreign_class;
		}
	}
	return $relationships;
}

sub _remove_column_files {
	my ($self, $columns) = @_;
	foreach my $column (@{$columns}) {
		my $remove_file_method = $column . '_remove';
		$self->$remove_file_method if $self->can($remove_file_method);
	}
	return;
}

sub delete_with_file {
	my $self = shift;
	return unless ref $self;
	my $primary_key = $self->meta->primary_key_column_names->[0];
	my $directory = File::Spec->catdir(_get_renderer_config($self)->{upload}->{path}, $self->stringify_class, $self->$primary_key);
	rmtree($directory) if -d $directory;
	return $self->delete();
}

sub stringify_me {
	my ($self, %args) = @_;
	my $class = ref $self;
	$class->prepare_renderer() unless $args{prepared} || $self->can('renderer_config');
	my @values;
	foreach my $column (sort {$a->ordinal_position <=> $b->ordinal_position} @{$self->meta->columns}) {
		my $column_definition_method = $column . '_definition';
		# filter primary keys and custom coded columns
		if ($self->can($column_definition_method) && $self->$column_definition_method->{stringify}) {
			my $for_view_method = $column . '_for_view';
			if ($self->can($for_view_method)) {
				push @values, $self->$for_view_method;
			}
			else {
				push @values, $self->$column;
			}
		}
	}

	return join _get_renderer_config($self)->{misc}->{stringify_delimiter}, @values if @values;
	my $primary_key = $self->meta->primary_key_column_names->[0];
	return $self->$primary_key;
}

sub stringify_class {
	my $self = shift;
	my $package_name = lc ref $self || lc $self;
	$package_name =~ s/::/_/gx;
	return $package_name;
}

# file util

sub _get_file_path {
	my ($self, $column) = @_;
	my $value = $self->$column;
	return unless $value;
	my $primary_key = $self->meta->primary_key_column_names->[0];
	return File::Spec->catfile(_get_renderer_config($self)->{upload}->{path}, $self->stringify_class, $self->$primary_key, $column, $value);
}

sub _get_file_url {
	my ($self, $column) = @_;
	my $value = $self->$column;
	return unless $value;
	my $primary_key = $self->meta->primary_key_column_names->[0];
	return File::Spec->catfile(_get_renderer_config($self)->{upload}->{url}, $self->stringify_class, $self->$primary_key, $column, CGI::escape($value));
}

# formatting methods

sub _create_timestamp {
	my ($self, $column) = @_;
	my $dt = DateTime->now->set_time_zone(_get_renderer_config($self)->{misc}->{time_zone});
	return $dt->dmy('/').' '.$dt->hms;
}

sub _edit_datetime {
	my ($self, $column) = @_;
	return unless $self->$column && ref $self->$column eq 'DateTime';
	return $self->$column->strftime('%d/%m/%Y %H:%M');
}

sub _edit_date {
	my ($self, $column) = @_;
	return $self->$column unless ref $self->$column eq 'DateTime';
	return $self->$column->dmy('/') if $self->$column;
	return;
}

sub _edit_time {
	my ($self, $column) = @_;
	return $self->$column unless ref $self->$column eq 'Time::Clock';
	return $self->$column->format('%H:%M');
}

sub _update_date {
	my ($self, $column, $value) = @_;
	return $self->$column(undef) unless $value;
	my ($d, $m, $y) = split /\/|\-/x, $value;
	if ($d =~ /^\d{4}$/x) { 
		my $temp_d = $d;
		$d = $y;
		$y = $temp_d;
	}
	my $dt;
	eval {$dt = DateTime->new(year => $y, month => $m, day => $d, time_zone => _get_renderer_config($self)->{misc}->{time_zone})};
	return if $@;
	return $self->$column($dt->ymd);
}

sub _update_time {
	my ($self, $column, $value) = @_;
	return $self->$column(undef) unless $value;
	my ($h, $m) = split ':', $value;
	my $t;
	eval {$t = Time::Clock->new(hour => $h, minute => $m)};
	return if $@;
	return $self->$column($t);
}

sub _update_file {
	my ($self, $column, $value) = @_;
	return unless $value;
	my $renderer_config = _get_renderer_config($self);
	my $primary_key = $self->meta->primary_key_column_names->[0]; 
	my $upload_path = File::Spec->catdir($renderer_config->{upload}->{path}, $self->stringify_class, $self->$primary_key, $column);
	mkpath($upload_path) unless -d $upload_path;

	my $file_name = "$value";
	$file_name =~ s/.*[\/\\](.*)/$1/;

	my ($actual_name, $extension) = ($file_name =~ /(.*)\.(.*)$/);
	$actual_name ||= $file_name;

	my $current_file = $self->$column;

	my $old_file;
	$old_file = File::Spec->catfile($upload_path, $current_file) if $current_file;
	my $new_file = File::Spec->catfile($upload_path, $file_name);

	if ($old_file eq $new_file && -e $old_file) {
		my $counter = 1;
		my $backup_file = File::Spec->catfile($upload_path, $actual_name.'-'.$counter.'.'.$extension);
		while (-e $backup_file) {
			$counter++;
			$backup_file = File::Spec->catfile($upload_path, $actual_name.'-'.$counter.'.'.$extension);
		}
		move($old_file, $backup_file);
		$old_file = $backup_file;
	}

	if (copy($value, File::Spec->catfile($upload_path, $file_name))) {
		unlink($old_file) if $old_file && !$renderer_config->{upload}->{keep_old_files};
		return $self->$column($file_name);
	}
	else {
		move($old_file, File::Spec->catfile($upload_path, $current_file)) if $old_file;
		return;
	}
}

sub _update_timestamp {
	my ($self, $column) = @_;
	return $self->$column(DateTime->now->set_time_zone(_get_renderer_config($self)->{misc}->{time_zone}));
}

sub _update_datetime {
	my ($self, $column, $value) = @_;
	return $self->$column(undef) if $value eq '';
	my ($date, $time) = split /\s+/x, $value;

	my ($d, $m, $y) = split /\/|\-/x, $date;
	if ($d =~ /^\d{4}$/x) { 
		my $temp_d = $d;
		$d = $y;
		$y = $temp_d;
	}
	
	my ($hour, $minute) = split ':', $time;

	my $dt;
	eval {$dt = DateTime->new(year => $y, month => $m, day => $d, hour => $hour, minute => $minute, time_zone => _get_renderer_config($self)->{misc}->{time_zone})};
	return if $@;
	return $self->$column($dt);
}

sub _view_file {
	my ($self, $column) = @_;
	my $value = $self->$column;
	return unless $value;
	my $file_url = _get_file_url($self, $column);
	return qq(<a href="$file_url">$value</a>);
}

sub _view_image {
	my ($self, $column) = @_;
	my $url = _get_file_url($self, $column);
	return unless $url;
	my $label = _label($column);
	return qq(<img src="$url" alt="$label"/>);
}

sub _view_media {
	my ($self, $column) = @_;
	return _view_image($self, $column) if $self->$column =~ /\.(gif|jpe?g|png|tiff?)$/x;
	return _view_video($self, $column) if $self->$column =~ /\.(ogv|ogg|mp4|m4v|mov)$/x;
	return _view_audio($self, $column);
}

sub _view_video {
	my ($self, $column) = @_;
	my $url = _get_file_url($self, $column);
	return unless $url;
	my $label = _label($column) . ' File';
	return qq(<video src="$url" controls="controls" preload="none"><a href="$url">$label</a></video>);
}

sub _view_audio {
	my ($self, $column) = @_;
	my $url = _get_file_url($self, $column);
	return unless $url;
	my $label = _label($column) . ' File';
	return qq(<audio src="$url" controls="controls" preload="none"><a href="$url">$label</a></audio>);
}

sub _view_address  {
	my ($self, $column) = @_;
	my $value = $self->$column;
	return unless $value;
	my $encoded_value = CGI::escape($value);
	return unless $value;return qq(<address><a href="http://maps.google.com/maps/api/staticmap?center=$encoded_value&zoom=14&size=400x225&sensor=false&markers=|$encoded_value">$value</a></address>);
}

sub _view_timestamp {
	my ($self, $column) = @_;
	return unless $self->$column && ref $self->$column eq 'DateTime';
	return '<time datetime="'. $self->$column->ymd . '">' . $self->$column->strftime('%d/%m/%Y %H:%M:%S') . '</time>';
}

sub _view_datetime {
	my ($self, $column) = @_;
	return unless $self->$column && ref $self->$column eq 'DateTime';
	return '<time datetime="'. $self->$column->ymd . '">' . $self->$column->strftime('%d/%m/%Y %H:%M') . '</time>';
}

sub _view_date {
	my ($self, $column) = @_;
	return unless $self->$column && ref $self->$column eq 'DateTime';
	return '<time datetime="'. $self->$column->ymd . '">' . $self->$column->day_name . ', '. $self->$column->day . ' ' . $self->$column->month_name . ' ' . $self->$column->year . '</time>';
}

sub _view_time {
	my ($self, $column) = @_;
	return $self->$column unless ref $self->$column eq 'Time::Clock';
	my $time = $self->$column->format('%H:%M');
	return '<time datetime="'. $time . '">' . $time . '</time>';
}

sub _search_boolean {
	my ($self, $column, $value) = @_;
	my $mapping;
	if ($self->meta->db->driver eq 'pg') {
		$mapping = {'Yes' => 'true', 'No' => 'false', 'yes' => 'true', 'no' => 'false'};
	}
	else {
		$mapping = {'Yes' => 1, 'No' => 0, 'yes' => 1, 'no' => 0};
	}
	return $mapping->{$value};
}

sub _search_date {
	my ($self, $column, $value) = @_;
	my ($date, $month_name, $year) = ($value =~ /(\d{1,2})?\s?([a-zA-Z]+)\s?(\d{4})?/x);
	if ($month_name) {
		my $month = 1;
		foreach my $abbr ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec') {
			last if $month_name =~ /^$abbr/ix;
			$month++;
		}
		
		return sprintf('%4d-%02d-%02d', $year, $month, $date) if $year && $month && $date;
		return sprintf('%4d-%02d', $year, $month) if $year && $month;
		return sprintf('%02d-%02d', $month, $date) if $month && $date;
		return sprintf('-%02d-', $month) if $month;
	}
	else {
		$value =~ s/\//-/gx;
		my ($d, $m, $y) = ($value =~ /^(0?[1-9]|[1-2][0-9]|3[0-1])\-(0?[1-9]|1[0-2])\-([0-9]{4})$/x);
		return sprintf('%4d-%02d-%02d', $y, $m, $d) if $d && $m && $y;
		($m, $y) = ($value =~ /^(0?[1-9]|1[0-2])\-([0-9]{4})$/x);
		return sprintf('%4d-%02d', $y, $m) if $m && $y;
		($d, $m) = ($value =~ /^(0?[1-9]|[1-2][0-9]|3[0-1])\-(0?[1-9]|1[0-2])$/x);
		return sprintf('%02d-%02d', $m, $d) if $m && $d;
		return $value;
	}
	return;
}

sub _search_timestamp {
	my ($self, $column, $value) = @_;
	my ($date_or_time, $time) = ($value =~ /^([\d\/\-]+)\s?([\d\:]+)?$/);
	if ($time) {
		return _search_date($self, $column, $date_or_time) . ' ' . $time;
	}
	else {
		return _search_date($self, $column, $date_or_time);
	}
}

sub _search_percentage {
	my ($self, $column, $value) = @_;
	return $value/100;
}

sub _remove_file {
	my ($self, $column) = @_;
	return unless ref $self && $self->$column;
	my $primary_key = $self->meta->primary_key_column_names->[0];
	my $directory = File::Spec->catdir(_get_renderer_config($self)->{upload}->{path}, $self->stringify_class, $self->$primary_key, $column);
	rmtree($directory) if -d $directory;
	return $self->$column(undef);
}

# misc util

sub _html_head {
	my ($args, $renderer_config) = @_;
	my $html_head = $args->{html_head} || $renderer_config->{misc}->{html_head};
	$html_head .= $renderer_config->{misc}->{js} if $args->{load_js} || ($renderer_config->{misc}->{load_js} && ! defined $args->{load_js});
	return $html_head;
}

sub _inherit_form_option {
	my ($option, $action, $args) = @_;
	unless (exists $args->{$action}->{$option}) {
		foreach my $other_form_action ('create', 'edit', 'copy') {
			next if $other_form_action eq $action || ! exists $args->{$other_form_action} || ref $args->{$other_form_action} ne 'HASH' || ! exists $args->{$other_form_action}->{$option};
			$args->{$action}->{$option} = $args->{$other_form_action}->{$option};
			last;
		}
	}
	return;
}

sub _unique {
	my ($column_config, $class, $column, $value, $form) = @_;

	my $existing;
	if ($column_config && exists $column_config->{format} && exists $column_config->{format}->{for_filter}) {
		$existing = $class->new($column => $column_config->{format}->{for_filter}->($class, $column, $value))->load(speculative => 1);
	}
	else {
		$existing = $class->new($column => $value)->load(speculative => 1);
	}
	return 1 unless $existing;

	my ($action, $object);

	if (ref $form eq 'HASH') {
		$action = $form->{button_action};
		$object = $form->{object} if $form->{object};
	}
	else {
		(my $prefix = $form->name) =~ s/_form$//x;
		$action = $form->field('action') || $form->field($prefix . '_action');
		$object = $form->field('object') || $form->field($prefix . '_object');
	}

	return unless $action eq 'edit' || $action eq 'update';
	my $primary_key = $class->meta->primary_key_column_names->[0];
	return 1 if $existing->$primary_key == $object;
	return;
}

sub _identify {
	my ($class, $prefix, $ui_type) = @_;
	return $prefix if defined $prefix;
	($prefix = lc $class) =~ s/::/_/gx;
	$prefix .= '_' . $ui_type;
	return $prefix;
}

sub _singularise_table {
	my ($table, $tables_are_singular) = @_;
	return $table if $tables_are_singular;
	return _singularise($table);
}

sub _pluralise_table {
	my ($table, $tables_are_singular) = @_;
	return Lingua::EN::Inflect::PL($table) if $tables_are_singular;
	return $table;
}

sub _singularise {
	my $word = shift;
	$word =~ s/ies$/y/ix;
	return $word if ($word =~ s/ses$/s/x);
	return $word if($word =~ /[aeiouy]ss$/ix);
	$word =~ s/s$//ix;
	return $word;
}

sub _title {
	my ($table_name, $prefix) = @_;
	return $table_name unless $prefix;
	$table_name =~ s/^$prefix//x;
	return $table_name;
}

sub _label {
	my $string = shift;
	$string =~ s/_/ /g;
	$string =~ s/\b(\w)/\u$1/gx;
	return $string;
}

sub _create_hidden_field {
	my $queries = shift;
	my $hidden_field;
	foreach my $query_key (keys %{$queries}) {
		if (ref $queries->{$query_key} eq 'ARRAY') {
			foreach my $value (@{$queries->{$query_key}}) {
				$hidden_field .= '<input name="'.$query_key.'" type="hidden" value="'.CGI::escapeHTML($value).'"/>';
			}
		}
		else {
			$hidden_field .= '<input name="'.$query_key.'" type="hidden" value="'.CGI::escapeHTML($queries->{$query_key}).'"/>';
		}
	}
	return $hidden_field;
}

sub _create_query_string {
	my $queries = shift;
	my $query_string;
	foreach my $query_key (keys %{$queries}) {
		if (ref $queries->{$query_key} eq 'ARRAY') {
			foreach my $value (@{$queries->{$query_key}}) {
				$query_string .= $query_key.'='.CGI::escape($value).'&amp;';
			}
		}
		else {
			$query_string .= $query_key.'='.CGI::escape($queries->{$query_key}).'&amp;';
		}
	}
	return $query_string;
}

sub _touch_up {
	my ($rendering, $cancel, $form_id) = @_;
	$rendering =~ s/onclick="this\.form\._submit\.value = this\.value;" type="submit" value="$cancel"/onclick="this.form.$form_id\_submit_cancel.value = 1;" type="submit" value="$cancel"/;
	return $rendering;
}

sub _alias_table {
	my ($with_require_objects, $class, $counter, $table_alias, $table_to_class) = @_;
	$with_require_objects = [$with_require_objects] unless ref $with_require_objects eq 'ARRAY';
	
	foreach my $with_require_object (@{$with_require_objects}) {
		if (exists $class->meta->{relationships}->{$with_require_object}) {
			if ($class->meta->{relationships}->{$with_require_object}->type eq 'many to many') {
				$table_alias->{$class->meta->{relationships}->{$with_require_object}->{map_class}} = 't' . ++$$counter;
				$table_to_class->{$class->meta->{relationships}->{$with_require_object}->{map_class}->meta->table} = $class->meta->{relationships}->{$with_require_object}->{map_class};
				$table_alias->{$class->meta->{relationships}->{$with_require_object}->{foreign_class}} = 't' . ++$$counter;
				$table_to_class->{$class->meta->{relationships}->{$with_require_object}->{foreign_class}->meta->table} = $class->meta->{relationships}->{$with_require_object}->{foreign_class};
			}
			else {
				$table_alias->{$class->meta->{relationships}->{$with_require_object}->{class}} = 't' . ++$$counter;
				$table_to_class->{$class->meta->{relationships}->{$with_require_object}->{class}->meta->table} = $class->meta->{relationships}->{$with_require_object}->{class};
			}
		}
	}

	return ($table_alias, $table_to_class);
}

sub _template {
	my ($template, $ui_type, $default) = @_;
 	if (ref $template eq 'HASH') {
		return $template->{$ui_type} if exists $template->{$ui_type} && $template->{$ui_type} ne 1;
		return $ui_type . '.tt';
	}
	return $ui_type . '.tt' if $template eq 1 || $default;
	return $template;
}

1;

__END__

=head1 NAME

Rose::DBx::Object::Renderer - Web UI Rendering for Rose::DB::Object

=head1 SYNOPSIS

  use Rose::DBx::Object::Renderer;

  use CGI;
  my $query = new CGI;
  print $query->header();

  # Load all tables in the local MySQL database named 'company'
  my $renderer = Rose::DBx::Object::Renderer->new(
    config => {
      db => {name => 'company', username => 'root', password => 'password'}
    },
    load => 1
  );
  
  
  # Render a form to add new employee
  Company::Employee->render_as_form();

  # Render an object as a form
  my $e = Company::Employee->new(id => 1);
  $e->load;
  $e->render_as_form();
  
  
  # Render the 'address' column as a link to a google map of the location
  print $e->address_for_view();

  
  # Render a table
  Company::Employee::Manager->render_as_table();

  # Render a table for all the employees who love 'Coding' with create, copy, edit, and delete access
  Company::Employee::Manager->render_as_table(
    get => {query => [hobby => 'Coding']}
    order => ['first_name', 'email', 'address', 'phone'],
    create => 1,
    copy => 1,
    edit => 1,
    delete => 1,
    searchable => ['first_name', 'address']
  );

  # Render a menu
  my $menu = Company::Employee::Manager->render_as_menu(
    order => ['Company::Employee', 'Company::Position'],
    edit => 1,
    delete => 1,
  );


  # Render a pie chart via Google Chart API
  Company::Employee::Manager->render_as_chart(
    type => 'pie',
    values => ['Coding', 'Cooking'],
    column => 'hobby',
  );

  # Render a bar chart
  Company::Employee::Manager->render_as_chart(
    type => 'bar',
    title => 'The Employee Bar Chart',
    description => 'A useful bar chart.',
    columns => ['salary', 'tax'],
    objects => [1, 2, 3],
    options => {chco => 'ff6600,ffcc00'}  # the color for each bar
  );


=head1 DESCRIPTION

Rose::DBx::Object::Renderer generates forms, tables, menus, and charts for L<Rose::DB::Object>. The generated UIs encapsulate sensible web conventions as default behaviours, such as rendering email addresses as 'mailto' links and enforce appropriate validation in forms. These default behaviours are highly configurable.

Rose::DBx::Object::Renderer uses L<CGI::FormBuilder> to generate forms and the Google Chart API to render charts. L<Template::Toolkit> is used for template processing, although UIs can be generated out of the box without using templates.

=head1 RESTRICTIONS

=over 4

=item * Must follow the default conventions in L<Rose::DB::Object>.

=item * Limited support for database tables with multiple primary keys.

=back

=head1 METHODS

=head2 C<new>

To instantiate a new Renderer object:

  my $renderer = Rose::DBx::Object::Renderer->new(config => {db => {name => 'company', username => 'root', password => 'root'}}, load => 1);

Since Renderer inherits from L<Rose::Object>, the above line is equivalent to:

  my $renderer = Rose::DBx::Object::Renderer->new();
  $renderer->config({db => {name => 'company', username => 'root', password => 'root'}});
  $renderer->load();

=head2 C<config>

A Renderer instance inherits the default configurations in Renderer, which is accessible by:

  my $config = $renderer->config();

C<config> accepts a hashref for configuring the Renderer object.

=head3 C<db>

The C<db> option is for configuring database related settings, for instance:

  $renderer->config({
    db => {
      name => 'product',
      type => 'Pg', # defaulted to 'mysql'
      host => '10.0.0.1',
      port => '5432',
      username => 'admin',
      password => 'password',
      tables_are_singular => 1,  # defines table name conventions, defaulted to undef
      table_prefix => 'app_', # specificies the prefix used in your table names if any, defaulted to undef
      new_or_cached => 0, # whether to use Rose::DB's new_or_cached() method, defaulted to 1
      check_class => 'Company::DB', # skip loading classes if the given class is already loaded (for persistent environments)
    }
  });

=head3 C<template>

The C<template> option specifies the template toolkit C<INCLUDE_PATH> and the base URL for static contents, such as javascript libraries or images:

  $renderer->config({
    ...
    template => {
      path => '../templates:../alternative',  # TT INCLUDE_PATH, defaulted to 'templates'
      url => '../images',  # defaulted to 'templates'
      options => {ABSOLUTE => 1, RELATIVE => 1, POST_CHOMP => 1} # defaulted to undef
    },
  });

=head3 C<upload>

Renderer needs a directory with write access to upload files. The C<upload> option defines file upload related settings:

  $renderer->config({
    ...
    upload => {
      path => '../files',  # the upload directory path, defaulted to 'uploads'
      url => '../files',  # the corresponding URL path, defaulted to 'uploads'
      keep_old_files => 1,  # defaulted to undef
    },
  });

=head3 C<form>

The C<form> option defines the global default behaviours of C<render_as_form>:

  $renderer->config({
    ...
    form => {
      download_message => 'View File',  # the name of the link for uploaded files, defaulted to 'View'
      remove_files => 1,  # allow users to remove uploaded files, default to undef
      remove_message => 'Remove File',  # the label of the checkbox for removing files, defaulted to 'Remove'
      cancel => 'Back',  # the name of the built-in 'Cancel' controller, defaulted to 'Cancel'
      delimiter => ' '  # the delimiter for handling column with muliple values, defaulted to ','
      action => '/app'  # set form action, defaulted to undef
    },
  });

These options can be also passed to C<render_as_form> directly to affect only the particular instance.

=head3 C<table>

The C<table> option defines the global default behaviours of C<render_as_table>:

  $renderer->config({
    ...
    table => {
      search_result_title => 'Looking for "[% q %]"?',
      empty_message => 'No matching records.', 
      per_page => 25,  # number of records per table, defaulted to 15
      pages => 5,  # the amount of page numbers in the table pagination, defaulted to 9
      no_pagination => 1,  # do not display pagination, defaulted to undef
      or_filter => 1,  # column filtering is joined by 'OR', defaulted to undef
      delimiter => '/',  # the delimiter for joining foreign objects in relationship columns, defaulted to ', '
      keyword_delimiter => '\s+',  # the delimiter for search keywords, defaulted to ','
      like_operator => 'like', # only applicable to Postgres, defaulted to undef, i.e. render_as_table() uses 'ilike' for Postgres by default
      form_options => ['order', 'template'], # options to be shared by other forms, defaulted to ['before', 'order', 'fields', 'template']
      cascade => ['template_data', 'extra'], # options to be cascaded into all forms, defaulted to ['template_url', 'template_path', 'template_options', 'query', 'renderer_config', 'prepared']
    },
  });

These options can be also passed to C<render_as_table> directly to affect only the particular instance.

=head3 C<menu>

The C<menu> option defines the global default behaviours of C<render_as_menu>:

  $renderer->config({
    ...
    menu => {
      cascade => ['template_data', 'extra'], # options to be cascaded into all tables, defaulted to ['create', 'edit', 'copy', 'delete', 'ajax', 'prepared', 'searchable', 'template_url', 'template_path', 'template_options', 'query', 'renderer_config']
    },
  });

These options can be also passed to C<render_as_menu> directly to affect only the particular instance.

=head3 C<columns>

Renderer has a built-in list of column definitions that encapsulate web conventions and behaviours. A column definition is a collection of column options. Column definitions are used by the rendering methods to generate web UIs. The built-in column definitions are stored inside C<columns>:

  my $config = $renderer->config();
  print join (', ', keys %{$config->{columns}});

For example, the column definition for 'email' would be:

  ...
  'email' => {
    required => 1,
    validate => 'EMAIL',
    sortopts => 'LABELNAME',
    comment => 'e.g. your.name@work.com',
    format => {
      for_view => sub {
        my ($self, $column) = @_;
        my $value = $self->$column;
        return unless $value;
        return qq(<a href="mailto:$value">$value</a>);}
    }
  },
  ...

We can also define new column definitions:

  $renderer->config({
    ...
    columns => {
      hobby => {
        label => 'Your Favourite Hobby',
        sortopts => 'LABELNAME',
        required => 1,
        options => ['Reading', 'Coding', 'Shopping']
     }
    },
  });

All options in each column definition are C<CGI::FormBuilder> field definitions, i.e. they are passed to L<CGI::FormBuilder> directly, except for:

=over

=item C<format>

The C<format> option is a hash of coderefs which get injected as object methods by C<load>. For instance, based on the 'email' column definition, we can print a 'mailto' link for the email address by calling:

  print $object->email_for_view;

Similarly, based on other column definitions, we can:

  # Print the date in 'DD/MM/YYYY' format
  print $object->date_for_view;

  # Store a password in MD5 hash
  $object->password_for_update('p@$$W0rD');
  $object->save();

  # Display an image formatted in HTML <img> tags
  print $object->image_for_view;

  # Print the url of the image
  print $object->image_url;

  # Prints the file path of the image
  print $object->image_path;

We can overwrite the existing formatting methods or define new ones. For instance, we can use the L<HTML::Strip> module to strip out HTML tags for the 'description' column type:

  use HTML::Strip;
  ...
  
  $renderer->config({
    ...
    columns => {
      description => {
        format => {
          for_update => sub {
            my ($self, $column, $value) = @_;
            return unless $value;
            my $hs = HTML::Strip->new(emit_spaces => 0);
            my $clean_text = $hs->parse($value);
            return $self->$column($clean_text);
          }
        }
      } 
    },
  });
  
  $renderer->load();
  ...
  $object->description_for_update('<html>The Lightweight UI Generator.</html>');
  $p->save();
  print $p->description;
  # prints 'The Lightweight UI Generator.'

Formatting methods are utilised by rendering methods. They take preference over the default CRUD methods. The C<for_create>, C<for_edit>, and C<for_update> methods are used by C<render_as_form>. When creating new objects, C<render_as_form> triggers the C<for_create> methods to format the default value of each column. When rendering an existing object as a form, however, the C<for_edit> methods are triggered to format column values. During form submissions, the C<for_update> methods are triggered to format the submitted form field values. The C<for_view>, C<for_search>, and C<for_filter> methods are used by C<render_as_table>. The C<for_view> methods are triggered to format column values for data presentation, the C<for_filter> methods are triggered during data filtering, and the C<for_search> methods are triggered during keyword searches.

=item C<unsortable>

This option defines whether a column is sortable. For instance, the 'password' column definition has the C<unsortable> option set to 1. This option is used by C<render_as_table>. Custom columns are always unsortable.

=item C<stringify>

This option specifies whether a column will be stringified by the C<stringify_me> object method.

=back

=head3 C<misc>

Other miscellaneous options are defined in C<misc>:

  my $custom_config = $renderer->config();

  # Print the built-in doctype and CSS
  print $custom_config->{misc}->{html_head};

  # Change the object stringify delimiter
  $custom_config->{misc}->{stringify_delimiter} = ', '; # defaulted to space

  # Change time zone
  $custom_config->{misc}->{time_zone} = 'Asia/Hong_Kong'; # defaulted to Australia/Sydney

  # loaded the JS or CSS defined in $custom_config->{misc}->{js}, defaulted to the latest jQuery and jQuery UI hosted by Google
  $custom_config->{misc}->{load_js} = 1; # defaulted to undef

  $renderer->config($custom_config);
  $renderer->load();

=head2 C<load>

C<load> uses L<Rose::DB::Object::Loader> to load L<Rose::DB::Object> classes dynamically. In order to take advantage of the built-in column definitions, C<load> employs the following logic to auto-assign column definitions to database columns:

  Column name exists in the Renderer object's config?
    Yes: Use that column definition.
    No: Is the column a foreign key?
      Yes: Apply the column options designed for foreign keys.
      No: Column name matches (regex) a column definition name?
        Yes: Use the first matching column definition.
        No: Column's metadata object type exists as column definition name?
          Yes: Use that column definition.
          No: Create a custom column definition by aggregating database column information.


C<load> accepts a hashref to pass parameters to the C<new> and C<make_classes> methods in L<Rose::DB::Object::Loader>. 

=over

=item C<loader>

The C<loader> option is a hashref that gets passed to the C<new> method in L<Rose::DB::Object::Loader>.

  $renderer->load({
    loader => {
      class_prefix => 'MyCompany',
    }
  });

=item C<make_classes>

Similarly, the C<make_classes> option is passed to the C<make_classes> method.

  $renderer->load({
    make_classes => {
      include_tables => ['customer', 'product'],
    }
  });

=back

C<load> returns an array of the loaded classes via the C<make_classes> method in L<Rose::DB::Object::Loader>. However, if the L<Rose::DB::Object> C<base_class> for the particular database already exists, which most likely happens in a persistent environment, C<load> will simply skip the loading process and return undef.

C<load> generates L<CGI::FormBuilder> validation subrefs to validate unique keys in forms. However, since column definitions are identified by column names, custom validation subrefs are required when there are multiple unique keys with the same table column name across different tables loaded via Renderer.

=head1 RENDERING METHODS

Rendering methods are exported for L<Rose::DB::Object> subclasses to generate web UIs. L<Rose::DB::Object> subclasses generated by calling C<load> will import the rendering methods automatically. However, we can also import the rendering methods directly into custom L<Rose::DB::Object> subclasses:

  # For object classes
  package Company::Employee
  use Rose::DBx::Object::Renderer qw(:object);
  ...
   
  # For manager classes
  package Company::Employee::Manager
  use Rose::DBx::Object::Renderer qw(:manager);
  ...

The following is a list of common parameters for the rendering methods:

=over 

=item C<template>

The template file name. When it is set to 1, rendering methods will try to find the default template based on the rendering method name. For example:

  Company::Employee->render_as_form(template => 1);
  # tries to use the template 'form.tt'

  Company::Employee::Manager->render_as_table(template => 1);
  # tries to use the template 'table.tt'

In C<render_as_table> or C<render_as_menu>, a hashref can be used as a shortcut to specify the default templates for all the forms and tables. For example:

  Company::Employee::Manager->render_as_menu(
    template => {menu => 'custom_menu.tt', table => 'custom_table.tt', form => 'custom_form.tt'}
  );

=item C<template_path>

The L<Template Toolkit>'s C<INCLUDE_PATH>.

=item C<template_url>

An URL path variable that is passed to the templates.

=item C<template_options>

Optional parameters to be passed to the L<Template Toolkit> constructor.

=item C<template_data>

A hashref to overwrite the variables passed to the template.

=item C<query>

Existing CGI query object. This is useful under a persistent environment, such as Fast CGI. Rendering methods initiates new CGI query objects unless an existing one has been provided.

=item C<html_head>

This is specifying custom DOCTYPE, CSS, or Javascript for the particular rendering method.

=item C<prefix> 

Define a prefix for the UI, e.g.:

  Company::Employee::Manager->render_as_table(prefix => 'employee_admin');

A prefix should be URL friendly. Adding a C<prefix> can prevent CGI param conflicts when rendering multiple UIs of the same class on the same web page.

=item C<title>

Define a title for the UI, e.g.:
  
  Company::Employee::Manager->render_as_table(title => 'Employee Directory');

=item C<description> 

Define a short description for the UI, e.g.:

  Company::Employee::Manager->render_as_table(description => 'Here you can view, search, and manage your employee details.');

=item C<no_head>

When set to 1, rendering methods will not include the default DOCTYPE and CSS defined in C<html_head>. This is useful when rendering multiple UIs in the same page.

=item C<load_js>

When set to 1, rendering methods will include the default C<js> into C<html_head>.

=item C<output>

When set to 1, the rendering methods will return the rendered UI instead of printing it directly. For example:
  
  my $form = Company::Employee->render_as_form(output => 1);
  print $form->{output};

=item C<extra>

A hashref of additional template variables. For example:

  Company::Employee->render_as_form(extra => {hobby => 'basketball'});

  # to access it within a template:
  [% extra.hobby %]

=item C<before>

A coderef to be executed prior to any rendering. This is useful for augmenting arguments passed to the rendering methods, for example:

  Company::Employee::Manager->render_as_table(
    order => ['first_name', 'last_name', 'position_id'],
    before => sub {
      my ($object, $args) = @_;
      # enable logged in users to access more data and functions
      if ($ENV{REMOTE_USER}) {
        $args->{order} = ['first_name', 'last_name', 'position_id', 'email', 'address'];
        $args->{create} = 1;
        $args->{edit} = 1;
      }
    }
  );

=item C<prepared>

When set to 1, rendering methods will not call C<prepare_renderer>. This is useful for physical Rose::DB::Object subclasses, when the formatting methods are either handcrafted or loaded previously.

=back

=head2 C<render_as_form>

C<render_as_form> renders forms and handles their submission.

  # Render a form for creating a new object
  Company::Employee->render_as_form();
  
  # Render a form for updating an existing object
  my $e = Company::Employee->new(id => 1);
  $e->load;
  $e->render_as_form();

=over

=item C<order>

C<order> is an arrayref for the order of the form fields.

=item C<fields>

A hashref to specify the L<CGI::FormBuilder> field definitions for this particular C<render_as_form> call. Any custom fields must be included in the C<order> arrayref in order to be shown.

  Company::Employee->render_as_form(
    order => ['username', 'favourite_cuisine'],
    fields => {
      favourite_cuisine => {required => 1, options => ['Chinese', 'French', 'Japanese']}
    }
  );

=item C<copy>

Instead of updating the calling object, we can clone the object by setting C<copy> to 1.

  ...
  $e->render_as_form(copy => 1);

=item C<queries>

An arrayref of query parameters to be converted as hidden fields.

  Company::Employee->render_as_form(
    queries => {
    'rm' => 'edit',
    'favourite_cuisine' => ['French', 'Japanese']
  });

Please note that when a prefix is used, all fields are renamed to 'C<prefix_fieldname>'. 

=item C<controllers> and C<controller_order>

Controllers are essentially callbacks. We can add multiple custom controllers to a form. They are rendered as submit buttons. C<controller_order> defines the order of the controllers, in other words, the order of the submit buttons. 

  my $form = Company::Employee->render_as_form(
    output => 1,
    controller_order => ['Hello', 'Good Bye'],
    controllers => {
      'Hello' => {
        create => sub {
          return if DateTime->now->day_name eq 'Sunday';
          return 1;
        },
        callback => sub {
          my $self = shift;
          if (ref $self) {
            return 'Welcome ' . $self->first_name;
          }
          else {
            return 'Employees cannot be added on Sundays';
          }
        }
      },
      'Good Bye' => sub {return 'Have fun!'}
    }
  );

  if (exists $form->{controller}) {
    print $form->{controller};
  }
  else {
    print $form->{output};
  }

Within the C<controllers> hashref, we can set the C<create> parameter to 1 so that the object is always inserted into the database before running the custom callback. We can also point C<create> to a coderef, in which case, the object is inserted into the database only if the coderef returns true. 

When rendering an object instance as a form, we can use the same mechanism to 'copy' or 'update' the object before running the custom callback, for instance:

  ...
  $e->render_as_form(
    controllers => {
      'Hello' => {
        update => 1,
        callback => sub{...}
      }
    }
  );

Another parameter within the C<controllers> hashref is C<hide_form>, which informs C<render_as_form> not to render the form after executing the controller.

=item C<form> 

A hashref that gets passed to the L<CGI::FormBuilder> constructor.

=item C<validate> 

Parameters for the L<CGI::FormBuilder>'s C<validate> method.

=item C<jserror>

When a template is used, C<render_as_form> sets L<CGI::FormBuilder>'s C<jserror> function name to 'C<notify_error>' so that we can always customise the error alert mechanism within the template (see the included 'form.tt' template).

=back

C<render_as_form> passes the following list of variables to a template:
  
  [% self %] - the calling object instance or class
  [% form %] - CGI::FormBuilder's form object
  [% field_order %] - the order of the form fields
  [% form_id %] - the form id
  [% form_submit %] - the form submit buttons with a custom 'Cancel' button
  [% title %] - the form title
  [% description %] - the form description
  [% doctype %] - the default html doctype
  [% html_head %] - the default html doctype and css
  [% no_head %] - the 'no_head' option
  [% cancel %] - the name of the 'Cancel' controller
  [% template_url %] - the default template URL
  [% extra %] - extra template variables

=head2 C<render_as_table>

C<render_as_table> renders tables for CRUD operations. 

=over

=item C<columns>

The C<columns> parameter can be used to set the label and value of a column, as well as whether the column is sortable. It can also be used to create custom columns, which do not exist in the underlying database.

  Company::Employee::Manager->render_as_table(
    order => ['first_name', 'custom_column'],
    columns => {
      'first_name' => {
        unsortable => 1
      },
      'custom_column' => {
        label => 'Favourite Drink',
        value => {
          1 => 'Tea',  # 1 is the primary key of the object
          2 => 'Coffee'
        },
      }
    }
  );

We can also nominate a custom C<accessor>, such that the table column values are populated via the nominated accessor, as opposed to the default column one. For example:

  Company::Employee::Manager->render_as_table(
    order => ['first_name', 'salary'],
    columns => {
      'salary' => {
         accessor => 'salary_with_bonus' 
      },
    }
  );

In this case, the values of the 'salary' column in the table are populated by calling C<salary_with_bonus>, instead of C<salary>.

=item C<order>

C<order> accepts an arrayref to define the order of the columns to be shown. The C<order> parameter also determines which columns are allowed to be filtered via URL when C<filterable> is not defined.

=item C<or_filter>

C<render_as_table> allows columns to be filtered via URL. For example:

  http://www.yoursite.com/yourscript.cgi?first_name=Danny&last_name=Liang

returns the records where 'first_name' is 'Danny' and 'last_name' is 'Liang'. By default, column queries are joined by "AND", unless C<or_filter> is set to 1.

=item C<filterable>

This specifies an arrayref of columns that are filterable via URL. This can be used to filter data in columns that are not shown, e.g.:

  Company::Employee::Manager->render_as_table(
    order => ['first_name', 'last_name', 'email'],
    filterable => ['first_name', 'last_name', 'email', 'state'],
  );

=item C<searchable>

The C<searchable> option enables keyword searches accross multiple table columns using the LIKE operator in SQL, including the columns of foreign objects:

  Company::Employee::Manager->render_as_table(
    get => {with_objects => [ 'position' ]},
    searchable => ['first_name', 'last_name', 'position.title'],
  );

This option adds a text field named 'q' in the rendered table for entering keywords. C<render_as_table()> grabs the value of the argument C<q> if it exists, otherwise pulls the value of the param 'q' from querystring.

Since PostgreSQL does not like mixing table aliases with real table names in queries, C<render_as_table()> tries to perform basic table aliasing for non-character based columns in PostgreSQL automatically. Please note that the corresponding tables in chained relationships defined via 'with_objects' and 'require_objects', such as 'vendor.region', will still require manual table aliasing if their columns are specified in the C<searchable> array.

In order to use the LIKE operator in SQL queries, C<render_as_table()> also performs type casting for non-character based columns, such as date, in PostgreSQL and SQLite.

By default, comma is the delimiter for seperating multiple keywords. This is configurable via C<config()>. 

Instead of an arrayref, you can also pass in 1, e.g.:

  Company::Employee::Manager->render_as_table(
    searchable => 1,
  );

In this case, all the columns of the given table will be searched.

=item C<like_operator>

The 'LIKE' operator for generating SQL queries when C<searchable> is used. Set this to 'like' to perform a case-sensitive search for PostgreSQL.

=item C<get>

C<get> accepts a hashref to construct database queries. C<get> is directly passed to the C<get> method of the manager class.

  Company::Employee::Manager->render_as_table(
    get => {
      per_page = 5,
      require_objects => [ 'position' ],
      query => ['position.title' => 'Manager'],
  });

=item C<get_from_sql>

C<get_from_sql> accepts arguments, such as an SQL statement, supported by the C<get_objects_from_sql> method from L<Rose::DB::Object::Manager>.

  Company::Employee::Manager->render_as_table(
    order => ['id', 'first_name', 'email'],
    get_from_sql => 'SELECT id, first_name, email FROM employee WHERE id % 2 = 0 ORDER BY id',
  );

C<get_from_sql> takes precedence over C<get>. The default table pagination will be also disabled.

=item C<objects>

C<objects> accepts an array of L<Rose::DB::Object> objects.

  Company::Employee::Manager->render_as_table(
    objects => Company::Employee::Manager->get_objects(query => [hobby => 'Coding']),
  );

C<objects> takes precedence over C<get_from_sql>. The default table pagination will be also disabled.

=item C<controllers> and C<controller_order>

The C<controllers> parameter works very similar to C<render_as_form>. C<controller_order> defines the order of the controllers.

  Company::Employee::Manager->render_as_table(
    controller_order => ['edit', 'Review', 'approve'],
    controllers => {
      'Review' => sub{my $self = shift; do_something_with($self);}
      'approve' => {
        label => 'Approve',
        hide_table => 1,
        queries => {approve => '1'}, 
        callback => sub {my $self = shift; do_something_else_with($self);
      }
    }
  );

Within the C<controllers> hashref, the C<queries> parameter allows us to define custom query strings for the controller. The C<hide_table> parameter informs C<render_as_table> not to render the table after executing the controller.

=item C<create> 

This enables the built-in 'create' controller when set to 1. 

  Company::Employee::Manager->render_as_table(create => 1);

Since C<render_as_form> is used to render the form, we can also pass a hashref to manipulate the generated form.

  Company::Employee::Manager->render_as_table(
    create => {title => 'Add New Employee', fields => {...}}
  );

=item C<edit>

Similar to C<create>, C<edit> enables the built-in 'edit' controller for updating objects.

=item C<copy>

C<copy> enables the built-in 'copy' controller for cloning objects.

=item C<delete>

When set to 1, C<delete> enables the built-in 'delete' controller for removing objects.

=item C<queries>

Similar to the C<queries> parameter in C<render_as_form>, C<queries> is an arrayref of query parameters, which will be converted to query strings. Please note that when a prefix is used, all query strings are renamed to 'C<prefix_querystring>'.

=item C<form_options>

An arrayref of form options that can be inherited by other forms.
  
  Company::Employee::Manager->render_as_table(
    form_options => ['order', 'template'],
    order => ['photo', 'first_name', 'last_name', 'email'],
    create => {
      before => sub {
        my ($object, $args) = @_;
        $args->{fields}->{status} = {static => 1, value => 'Pending'};
      },
      order => ['first_name', 'last_name', 'photo', 'email', 'phone', 'status'],
      template => 'custom_form.tt',
    },
    edit => 1,
    copy => 1,
  );

In the above example, both the form for 'edit' and 'copy' will share the exact same field order and TT template with the form for 'create', despite the fact that none of those options are defined directly. However, the 'before' callback will not be triggered in the 'edit' or 'copy' form since the C<form_options> parameter prevents that option being inherited.

=item C<url>

Unless a url is specified in C<url>, C<render_as_table> will resolve the self url using CGI.

=item C<ajax> and C<ajax_template>

These two parameters are designed for rendering Ajax-enabled tables. When C<ajax> is set to 1, C<render_as_table> tries to use the template 'table_ajax.tt' for rendering, unless it is defined via C<ajax_template>. C<render_as_table> also passes a variable called 'ajax' to the template and sets it to 1 when a CGI param named 'ajax' (assuming no prefix is in use) is found, indicating the current request is an ajax request.

=back

Within a template, we can loop through objects using the C<[% table %]> variable. Alternatively, we can use the C<[% objects %]> variable.

C<render_as_table> passes the following list of variables to a template:
  
  [% table %] - the hash for the formatted table, see the sample template 'table.tt' 
  [% objects %] - the raw objects returned by the 'get_object' method
  [% column_order %] - the order of the columns
  [% template_url %] - the default template URL
  [% table_id %] - the table id
  [% title %] - the table title
  [% description %] - the table description
  [% no_pagination %] - the 'no_pagination' option
  [% q %] - the keyword query for search
  [% query_string %] - a hash of URL encoded query strings
  [% query_hidden_fields %] - CGI queries converted into hidden fields; it is used by the keyword search form
  [% param_list %] - a list of CGI param names with the table prefix, e.g. the name of the keyword search box is [% param_list.q %]
  [% searchable %] - the 'searchable' option
  [% sort_by_column %] - the column to be sorted 
  [% doctype %] - the default html doctype
  [% html_head %] - the default html doctype and css
  [% no_head %] - the 'no_head' option
  [% ajax %] - the ajax variable for checking whether the current CGI request is a ajax request
  [% url %] - the base url
  [% extra %] - extra template variables

=head2 C<render_as_menu>

C<render_as_menu> generates a menu with the given list of classes and renders a table for the current class. We can have fine-grained control over each table within the menu. For example, we can alter the 'date_of_birth' field inside the 'create' form of the 'Company::Employee' table inside the menu:

  Company::Employee::Manager->render_as_menu (
    create => 1,
    edit => 1,
    delete => 1,
    copy => 1,
    searchable => 1,
    order => ['Company::Employee', 'Company::Position'],
    items => {
      'Company::Employee' => {
        create => {
          fields => {date_of_birth => {required => 1}}
        }
      },
      'Company::Position' => {
        title => 'Current Positions',
      }
    },
  );

=over

=item C<order>

The C<order> parameter defines the list of classes to be shown in the menu as well as their order. The current item of the menu is always the calling class, i.e. C<Company::Employee::Manager> in the example.

=item C<items>

The C<items> parameter is a hashref of parameters to control each table within the menu.

=item C<create>, C<edit>, C<copy>, C<delete>, C<searchable>, C<template>, C<ajax>, and C<prepared>

These parameters are shortcuts which get passed to all the underlying tables rendered by the menu.

=item C<current>

The class name for the current tab. By default, the caller class is the current tab.

=back

C<render_as_menu> passes the following list of variables to a template:

  [% template_url %] - the default template URL
  [% menu_id %] - the menu id
  [% title %] - the menu title
  [% description %] - the menu description
  [% items %] - the hash for the menu items
  [% item_order %] - the order of the menu items
  [% current %] - the current menu item
  [% content %] - the output of the table
  [% hide %] - whether the menu should be hidden
  [% doctype %] - the default html doctype
  [% html_head %] - the default html doctype and css
  [% no_head %] - the 'no_head' option
  [% extra %] - extra template variables

=head2 C<render_as_chart>

C<render_as_chart> renders pie, line, and vertical bar charts via the Google Chart API.

=over

=item C<type>

This can be 'pie', 'bar', or 'line', which maps to the Google chart type (cht) 'p', 'bvg', and 'ls' respectively.

=item C<column> and C<values>

These two parameters are only applicable to pie charts. C<column> defines the column of the table in which the values are compared. The C<values> parameter is a list of values to be compared in that column, i.e. the slices.

=item C<columns> and C<objects>

These two parameters are only applicable to bar and line charts. C<columns> defines the columns of the object to be compared. The C<objects> parameter is a list of object IDs representing the objects to be compared.

=item C<options>

A hashref for specifying Google Chart API options, such as the chart type, size, labels, or data. This hashref is serialised into a query string.

=item C<engine>

Accepts a coderef to plug in your own charting engine.

=back

C<render_as_chart> passes the following list of variables to a template:

  [% template_url %] - the default template URL
  [% chart_id %] - the chart id
  [% title %] - the chart title
  [% description %] - the chart description
  [% chart %] - the chart
  [% options %] - the 'options' hash
  [% doctype %] - the default html doctype
  [% html_head %] - the default html doctype and css
  [% no_head %] - the 'no_head' option
  [% extra %] - extra template variables

=head1 OBJECT METHODS

Apart from the formatting methods injected by C<load>, there are several lesser-used object methods:

=head2 C<delete_with_file>

This is a wrapper of the object's C<delete> method to remove any uploaded files associated:

  $object->delete_with_file();

=head2 C<stringify_me>

Stringifies the object instance, e.g.:

  $object->first_name('John');
  $object->last_name('Smith');

  print $object->stringify_me();
  # prints 'John Smith';

It also accept the C<prepared> parameter.

=head2 C<stringify_class>

Stringifies the class name: 

  print Company::Employee->stringify_class();
  # prints 'company_employee'

=head2 C<prepare_renderer>

This is called by Renderer's C<load> method internally. It generates the column formatting methods, column definition methods, as well as a C<renderer_config> method for the L<Rose::DB::Object> subclass. These generated methods are called by the rendering methods, e.g. C<render_as_form>. Thus, it would be useful for physical Rose::DB::Object subclasses to call C<prepare_renderer> explicitly, prior to running the rendering methods, unless those relevant methods are handcrafted. C<prepare_renderer> returns the renderer config hashref generated for the calling L<Rose::DB::Object> subclass.

  my $config = Company::Employee->prepare_renderer();
  $config->{upload}->{path} = '/path/for/file/uploads'; # set the path for file upload
  
  print Company::Employee->email_for_view(); # call the 'for view' method of the email column

  my $employee_config = Company::Employee->renderer_config(); # retrieve the complete config hashref
  my $email_definition = Company::Employee->email_definition(); # retrieve just the column definition hashref for the email column


=head1 SAMPLE TEMPLATES

There are four sample templates: 'form.tt', 'table.tt', 'menu.tt', and 'chart.tt' in the 'templates' folder of the TAR archive.

=head1 SEE ALSO

L<Rose::DB::Object>, L<CGI::FormBuilder>, L<Template::Toolkit>, L<http://code.google.com/apis/chart/>

=head1 AUTHOR

Xufeng (Danny) Liang (danny.glue@gmail.com)

=head1 COPYRIGHT & LICENSE

Copyright 2008-2010 Xufeng (Danny) Liang, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut