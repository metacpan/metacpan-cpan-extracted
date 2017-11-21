package QBit::Validator::Type::scalar;
$QBit::Validator::Type::scalar::VERSION = '0.011';
use qbit;

use base qw(QBit::Validator::Type);

use Exception::Validator;

#order is important
my $OPTIONS = [
    {name => 'optional', required => TRUE},
    {name => 'eq'},
    {name => 'regexp'},
    {name => 'min'},
    {name => 'max'},
    {name => 'len_min'},
    {name => 'len'},
    {name => 'len_max'},
    {name => 'in'},
];

sub _get_options {
    my ($self) = @_;

    return clone($OPTIONS);
}

sub _get_options_name {
    return map {$_->{'name'}} @$OPTIONS;
}

sub optional {
    my ($self, $qv, $data, $template, $option, @path_field) = @_;

    if (ref($data)) {
        $qv->_add_error($template, gettext('Data must be SCALAR'), \@path_field);

        return FALSE;
    }

    if ($template->{$option} && !defined($data)) {
        $qv->_add_ok(\@path_field);

        return FALSE;
    } elsif (!$template->{$option} && !defined($data)) {
        unless (exists($template->{'eq'})) {
            $qv->_add_error($template, gettext('Data must be defined'), \@path_field);

            return FALSE;
        }
    }

    return TRUE;
}

sub eq {
    my ($self, $qv, $data, $template, $option, @path_field) = @_;

    if (!defined($template->{$option})) {
        if (defined($data)) {
            $qv->_add_error($template, gettext('Data must be null'), \@path_field);

            return FALSE;
        } else {
            return TRUE;
        }
    } elsif (!defined($data)) {
        $qv->_add_error($template, gettext('Data must be defined'), \@path_field);

        return FALSE;
    }

    throw Exception::Validator gettext('Option "%s" must be numeric', $option)
      unless looks_like_number($template->{$option});

    unless (looks_like_number($data)) {
        $qv->_add_error($template, gettext('The data must be numeric, but got "%s"', $data), \@path_field);

        return FALSE;
    }

    unless ($data == $template->{$option}) {
        $qv->_add_error($template, gettext('Got value "%s" not equal "%s"', $data, $template->{$option}), \@path_field);

        return FALSE;
    }

    return TRUE;
}

sub regexp {
    my ($self, $qv, $data, $template, $option, @path_field) = @_;

    throw Exception::Validator gettext('Option "%s" must be type "Regexp"', $option)
      if !defined($template->{$option}) || ref($template->{$option}) ne 'Regexp';

    if ($data !~ $template->{$option}) {
        $qv->_add_error($template, gettext('Got value "%s" do not fit the regular expression', $data), \@path_field);

        return FALSE;
    }

    return TRUE;
}

sub min {
    my ($self, $qv, $data, $template, $option, @path_field) = @_;

    throw Exception::Validator gettext('Option "%s" must be numeric', $option)
      unless looks_like_number($template->{$option});

    unless (looks_like_number($data)) {
        $qv->_add_error($template, gettext('The data must be numeric, but got "%s"', $data), \@path_field);

        return FALSE;
    }

    if ($data < $template->{$option}) {
        $qv->_add_error($template, gettext('Got value "%s" less then "%s"', $data, $template->{$option}), \@path_field);

        return FALSE;
    }

    return TRUE;
}

sub max {
    my ($self, $qv, $data, $template, $option, @path_field) = @_;

    throw Exception::Validator gettext('Option "%s" must be numeric', $option)
      unless looks_like_number($template->{$option});

    unless (looks_like_number($data)) {
        $qv->_add_error($template, gettext('The data must be numeric, but got "%s"', $data), \@path_field);

        return FALSE;
    }

    if ($data > $template->{$option}) {
        $qv->_add_error($template, gettext('Got value "%s" more than "%s"', $data, $template->{$option}), \@path_field);

        return FALSE;
    }

    return TRUE;
}

sub len_min {
    my ($self, $qv, $data, $template, $option, @path_field) = @_;

    throw Exception::Validator gettext('Option "%s" must be positive number', $option)
      if !defined($template->{$option}) || $template->{$option} !~ /\A[0-9]+\z/;

    if (length($data) < $template->{$option}) {
        $qv->_add_error($template, gettext('Length "%s" less then "%s"', $data, $template->{$option}), \@path_field);

        return FALSE;
    }

    return TRUE;
}

sub len {
    my ($self, $qv, $data, $template, $option, @path_field) = @_;

    throw Exception::Validator gettext('Option "%s" must be positive number', $option)
      if !defined($template->{$option}) || $template->{$option} !~ /\A[0-9]+\z/;

    unless (length($data) == $template->{$option}) {
        $qv->_add_error($template, gettext('Length "%s" not equal "%s"', $data, $template->{$option}), \@path_field);

        return FALSE;
    }

    return TRUE;
}

sub len_max {
    my ($self, $qv, $data, $template, $option, @path_field) = @_;

    throw Exception::Validator gettext('Key "%s" must be positive number', $option)
      if !defined($template->{$option}) || $template->{$option} !~ /\A[0-9]+\z/;

    if (length($data) > $template->{$option}) {
        $qv->_add_error($template, gettext('Length "%s" more than "%s"', $data, $template->{$option}), \@path_field);

        return FALSE;
    }

    return TRUE;
}

sub in {
    my ($self, $qv, $data, $template, $option, @path_field) = @_;

    throw Exception::Validator gettext('Key "%s" must be defined', $option) unless defined($template->{$option});

    $template->{$option} = [$template->{$option}] if ref($template->{$option}) ne 'ARRAY';

    unless (in_array($data, $template->{$option})) {
        $qv->_add_error($template,
            gettext('Got value "%s" not in array: %s', $data, join(', ', @{$template->{$option}})),
            \@path_field);

        return FALSE;
    }

    return TRUE;
}

TRUE;
