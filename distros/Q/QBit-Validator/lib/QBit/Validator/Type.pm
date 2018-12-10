package QBit::Validator::Type;
$QBit::Validator::Type::VERSION = '0.012';
use qbit;

use base qw(QBit::Class);

use Exception::Validator;
use Exception::Validator::FailedField;

sub get_all_options_name {
    my ($self) = @_;

    return qw(message msg skip optional), $self->get_options_name(), qw(check);
}

sub get_options_name {()}

sub get_checks_by_template {
    my ($self, $qv, $template, $path) = @_;

    $self->pre_process_template($template);

    my @checks         = ();
    my %exists_options = ();

    foreach my $option ($self->get_all_options_name()) {
        if (exists($template->{$option})) {
            $exists_options{$option} = TRUE;

            if ($option eq 'message' || $option eq 'msg') {
                $qv->{'__CUSTOM_ERRORS__'} = $template->{$option};

                next;
            }

            push(@checks, $self->{$option}->($qv, $template->{$option}, $template));
        }
    }

    my @unknown_options = grep {!$exists_options{$_}} keys(%$template);
    throw gettext('Unknown options: %s for type: %s', join(', ', @unknown_options), $template->{'type'})
      if @unknown_options;

    if (!$exists_options{'optional'} && (!exists($template->{'eq'}) || defined($template->{'eq'}))) {
        unshift(@checks, $self->{'required'}->($qv));
    }

    return @checks;
}

sub pre_process_template {}

sub skip {
    my ($qv, $val, $template) = @_;

    return $val ? sub {0} : ();
}

sub optional {
    my ($qv) = @_;

    return sub {
        return FALSE unless defined($_[1]);
      }
}

sub required {
    my ($qv) = @_;

    return sub {
        throw gettext('Data must be defined') unless defined $_[1];

        return TRUE;
      }
}

sub check {
    my ($qv, $checks) = @_;

    throw Exception::Validator gettext('Option "%s" must be array of code', 'check')
      if !defined($checks)
      || ref($checks) ne 'ARRAY'
      || !@$checks
      || grep {ref($_) ne 'CODE'} @$checks;

    return sub {
        my ($qv, $data) = @_;

        my $error;
        my $error_msg;
        try {
            foreach my $check (@$checks) {
                $check->($qv, $data);
            }
        }
        catch Exception::Validator with {
            $error     = TRUE;
            $error_msg = shift->message;
        }
        catch {
            $error     = TRUE;

            $qv->use_errors_handler(shift);

            $error_msg = gettext('Internal error');
        };

        if ($error) {
            throw FF $error_msg, check_error => TRUE;
        }

        return TRUE;
      }
}

sub init {
    my ($self) = @_;

    $self->SUPER::init();

    foreach (qw(skip optional required check)) {
        $self->{$_} = \&$_;
    }
}

TRUE;
