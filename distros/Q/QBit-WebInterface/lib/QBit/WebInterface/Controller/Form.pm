package QBit::WebInterface::Controller::Form;
$QBit::WebInterface::Controller::Form::VERSION = '0.030';
use qbit;

use base qw(QBit::Class);

use Exception::Form;
use Exception::WebInterface::Controller::CSRF;

__PACKAGE__->mk_ro_accessors(qw(controller));

our $FIELDS_NAMESPACE = 'QBit::WebInterface::Controller::Form::Field::';

sub init {
    my ($self) = @_;

    weaken($self->{'controller'});

    my @default_fields = (
        {type => 'hidden', name => 'save'},
        $self->controller->request->param('retpath') ? {name => 'retpath', type => 'hidden'} : (),
        $self->controller->app->form_fields(),
    );

    $self->{'__FIELDS__'} = [];
    foreach my $field (@default_fields, @{$self->{'fields'} || []}) {
        my $field_class  = "$FIELDS_NAMESPACE$field->{'type'}";
        my $field_module = "$field_class.pm";
        $field_module =~ s/::/\//g;

        if (require($field_module)) {
            throw gettext('Field class must be QBit::WebInterface::Controller::Form::Field descendant')
              unless $field_class->isa('QBit::WebInterface::Controller::Form::Field');
            push(@{$self->{'__FIELDS__'}}, $field_class->new(%$field, form => $self));
        } else {
            throw gettext('Unknown field type "%s"', $_->{'type'});
        }
    }

    $self->{'__FIELDS_HS__'} = {};
    foreach my $field (@{$self->{'__FIELDS__'}}) {
        $self->{'__FIELDS_HS__'}{$field->{'name'} || ''} ||= [];
        push(@{$self->{'__FIELDS_HS__'}{$field->{'name'} || ''}}, $field);
    }
}

sub get_fields {
    return $_[0]->{'__FIELDS__'};
}

sub get_fields_hs {
    return $_[0]->{'__FIELDS_HS__'};
}

sub get_field {
    return $_[0]->{'__FIELDS_HS__'}->{$_[1]}[0];
}

sub set_field_error {
    my ($self, $field_name, $error) = @_;

    throw gettext('Error class must be Exception descendant.')
      unless blessed($error) && $error->isa('Exception');

    $self->{'__FIELDS_ERROR__'}{$field_name} = $error;
    return FALSE;
}

sub get_field_names {
    my ($self) = @_;

    return map {$_->{'name'}} @{$self->get_fields()};
}

sub break {
    my ($self, @data) = @_;

    $self->{'__BREAK_PROCESS__'} = 1;
    return @data;
}

sub process {
    my ($self, %opts) = @_;

    return $self->denied($self->controller)
      if exists($self->{'check_rights'}) && !$self->controller->check_rights(@{$self->{'check_rights'}});

    $self->{'__BREAK_PROCESS__'} = 0;
    my @pre_process_data = $self->{'pre_process'}($self) if exists($self->{'pre_process'});
    return @pre_process_data if $self->{'__BREAK_PROCESS__'};

    $self->{'__FIELDS_ERROR__'} = {};
    delete($self->{'__ERROR__'});

    my $retpath = $self->controller->request->param('retpath');
    $self->{'__FIELDS_HS__'}{'retpath'}[0]{'value'} = $retpath if $retpath;

    my $pseudo_url = $self->controller->get_option('cur_cmdpath') . '/' . $self->controller->get_option('cur_cmd');

    if ($self->controller->request->param('save') && !$opts{'no_save'}) {
        if ($self->controller->check_anti_csrf_token($self->controller->request->param('save'), url => $pseudo_url)) {
            foreach my $field (@{$self->{'__FIELDS__'}}) {
                try {
                    $field->process($self->controller);
                }
                catch Exception::Form with {
                    $self->set_field_error($field->{'name'}, shift);
                };
            }

            if (!%{$self->{'__FIELDS_ERROR__'}} && exists($self->{'check'})) {
                try {
                    $self->{'check'}($self);
                }
                catch Exception::Form with {
                    $self->{'__ERROR__'} = $_[0];
                };
            }

            if (   !%{$self->{'__FIELDS_ERROR__'}}
                && !exists($self->{'__ERROR__'})
                && exists($self->{'save'}))
            {
                try {
                    $self->{'save'}($self, $self->controller);
                }
                catch Exception::Form with {
                    $self->{'__ERROR__'} = $_[0];
                };
            }

            if (keys(%{$self->{'__FIELDS_ERROR__'}}) || $self->{'__ERROR__'}) {
                return $self->_get_html($self->controller);
            }

            return $self->_on_complete($self->controller);
        } else {
            throw Exception::WebInterface::Controller::CSRF gettext('CSRF has been detected');
        }
    } else {
        $self->{'__FIELDS_HS__'}{'save'}[0]{'value'} = $self->controller->gen_anti_csrf_token(url => $pseudo_url);
        return $self->_get_html($self->controller);
    }
}

sub get_value {
    my ($self, $name) = @_;

    return exists($self->{'__FIELDS_HS__'}{$name || ''}[0]) ? $self->{'__FIELDS_HS__'}{$name || ''}[0]->value() : undef;
}

sub start_form_html {
    my ($self) = @_;

    my $html = '<form class="form-horizontal" method="post"'
      . (defined($self->{'enctype'}) ? " enctype=\"$self->{'enctype'}\"" : '') . '>';
    $html .= '<fieldset>';
    $html .= '<legend>' . html_encode($self->{'title'}) . '</legend>' if defined($self->{'title'});

    $html .= '<p class="text-info">' . html_encode($self->{'description'}) . '</p>'
      if defined($self->{'description'});

    $html .= '<p class="text-error">' . html_encode($self->{'__ERROR__'}->message()) . '</p>'
      if exists($self->{'__ERROR__'});

    my $success_message = $self->{'controller'}->stash_delete($self->get_stash_form_name('complete_message'));
    $html .= '<p class="text-success">' . html_encode($success_message) . '</p>' if defined($success_message);

    $html .= $_->as_html() foreach grep {$_->is_hidden()} @{$self->{'__FIELDS__'}};

    return $html;
}

sub finish_form_html {
    my ($self) = @_;

    my $html .= '</fieldset>';
    $html .= '</form>';

    return $html;
}

sub as_html {
    my ($self) = @_;

    my $html = $self->start_form_html();
    $html .= $_->as_html() foreach grep {!$_->is_hidden()} @{$self->{'__FIELDS__'}};
    $html .= $self->finish_form_html();

    return $html;
}

sub denied {return $_[1]->denied()}

sub get_stash_form_name {
    my ($self, $name) = @_;

    my $stash_name =
      $self->controller->get_option('cur_cmdpath') . '_' . $self->controller->get_option('cur_cmd') . '_' . $name;

    return $stash_name;
}

sub _on_complete {
    my ($self, $controller) = @_;

    if (defined($self->{complete_message})) {
        my $stash_name = $self->get_stash_form_name('complete_message');

        $controller->stash_set($stash_name, $self->{complete_message});
    }

    my $retpath = $controller->request->param('retpath');
    my %redirect_opts = $self->{'redirect_opts'} ? %{$self->{'redirect_opts'}} : ();
    if ($retpath) {
        return $controller->redirect2url_internal($retpath);
    } else {
        return $controller->redirect($self->{'redirect'}, %redirect_opts);
    }
}

sub _get_html {
    my ($self, $controller) = @_;

    return $controller->from_template(($self->{'template'} || 'form.tt2'),
        vars => {%{$self->{'vars'} || {}}, form => $self});
}

TRUE;
