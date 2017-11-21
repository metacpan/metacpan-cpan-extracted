package QBit::Validator::Type;
$QBit::Validator::Type::VERSION = '0.011';
use qbit;

use base qw(QBit::Class);

use Exception::Validator;

__PACKAGE__->abstract_methods(qw(_get_options _get_options_name));

sub check_options {
    my ($self, $qv, $data, $template, $already_check, @path_field) = @_;

    return FALSE if $qv->has_error(\@path_field);

    if ($template->{'skip'}) {
        $qv->_add_ok(\@path_field);

        return TRUE;
    }

    my @options =
      map {$_->{'name'}} grep {exists($template->{$_->{'name'}}) || $_->{'required'}} @{$self->_get_options()};

    foreach my $option (@options) {
        if ($self->can($option)) {
            last unless $self->$option($qv, $data, $template, $option, @path_field);
        } else {
            throw Exception::Validator gettext('Option "%s" don\'t have check sub', $option);
        }
    }

    return FALSE if $qv->has_error(\@path_field);

    if (exists($template->{'check'}) && !$$already_check) {
        $$already_check = TRUE;

        throw Exception::Validator gettext('Option "%s" must be code', 'check')
          if !defined($template->{'check'}) || ref($template->{'check'}) ne 'CODE';

        if (!defined($data) && $template->{'optional'}) {
            $qv->_add_ok(\@path_field);

            return TRUE;
        }

        my $error;
        my $error_msg;
        try {
            $template->{'check'}($qv, $data, $template, @path_field);
        }
        catch Exception::Validator with {
            $error     = TRUE;
            $error_msg = shift->message;
        }
        catch {
            $error     = TRUE;
            $error_msg = gettext('Internal error');
        };

        if ($error) {
            $qv->_add_error($template, $error_msg, \@path_field, check_error => TRUE);

            return FALSE;
        }
    }

    $qv->_add_ok(\@path_field);

    return TRUE;
}

sub get_all_options_name {
    my ($self) = @_;

    return qw(skip type check msg), $self->_get_options_name();
}

sub merge_templates {
    my ($self, $template, $template2) = @_;

    return {
        type => $template2->{'type'},
        (
            map {$_ => $template2->{$_}}
              grep {!exists($template->{$_}) && $_ ne 'msg'} keys(%$template2)
        ),
        map {$_ => $template->{$_}} grep {$_ ne 'type' && $_ ne 'check'} keys(%$template)
    };
}

TRUE;
