package QBit::WebInterface::Controller::Form::Field;
$QBit::WebInterface::Controller::Form::Field::VERSION = '0.031';
use qbit;

use base qw(QBit::Class);

use Exception::Form;

__PACKAGE__->mk_accessors(qw(form name value));
__PACKAGE__->abstract_methods(qw(control_html));

sub init {
    my ($self) = @_;

    $self->SUPER::init();
    weaken($self->{'form'});

    ($self->{items_key}, $self->{items_label}) = %{$self->{items_key} || {'value' => 'label'}};
}

sub is_hidden {0}

sub value_from_request {
    my ($self, $request) = @_;

    my $value = $request->param($self->{'name'}, $self->{'value'});
    $value = '' unless defined($value);

    return $value;
}

sub clean {$_[1]}

sub check {1}

sub trim {
    for ($_[1]) {
        s/^\s+//;
        s/\s+$//;
    }

    return $_[1];
}

sub as_html {
    my ($self) = @_;
    return
        '<div class="control-group'
      . ($self->has_error()  ? ' error'    : '')
      . ($self->{'required'} ? ' required' : '') . '">'
      . $self->_html_label()
      . '<div class="controls">'
      . $self->control_html()
      . '</div>'
      . '</div>';
}

sub process {
    my ($self, $controller) = @_;

    $self->{'value'} = $self->value_from_request($controller->request);
    $self->{'value'} = $self->trim($self->{'value'}) if $self->{'trim'};
    $self->{'value'} = $self->clean($self->{'value'});
    $self->{'value'} = $self->{'clean_func'}($self->{'value'})
      if exists($self->{'clean_func'});

    throw Exception::Form gettext('Required field')
      if $self->{'required'} && $self->{'value'} !~ /\S/;

    $self->check();
    $self->{'check'}($self, $self->{'value'})
      if exists($self->{'check'});
}

sub has_error {
    my ($self) = @_;

    return FALSE unless defined $self->{'name'};

    return exists($self->form->{'__FIELDS_ERROR__'}{$self->{'name'}});
}

sub error_text {
    my ($self) = @_;

    return html_encode($self->form->{'__FIELDS_ERROR__'}{$self->{'name'}}->message());
}

sub _html_label {
    my ($self, %opts) = @_;

    return '' unless defined($self->{'label'}) && length($self->{'label'});

    return '<label class="control-label"'
      . (
        defined($self->{'id'}) ? ' for="' . html_encode($self->{'id'}) . '"'
        : ''
      )
      . '>'
      . html_encode(
        ref($self->{'label'}) eq 'CODE' ? $self->{'label'}()
        : $self->{'label'}
      ) . '</label>';
}

sub _class {
    my ($self, $req_class) = @_;

    $req_class = [] unless defined($req_class);
    $req_class = [$req_class] if ref($req_class) ne 'ARRAY';

    my $class = $self->{'class'};
    $class = [] unless defined($class);
    $class = [$class] if ref($class) ne 'ARRAY';

    return @$req_class + @$class ? ' class="' . join(' ', map {html_encode($_)} @$req_class, @$class) . '"' : '';
}

sub _html_error {
    my ($self) = @_;

    return $self->has_error() ? '<span class="help-inline">' . $self->error_text() . '</span>' : '';
}

TRUE;
