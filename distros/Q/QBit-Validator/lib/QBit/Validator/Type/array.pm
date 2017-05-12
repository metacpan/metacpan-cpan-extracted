package QBit::Validator::Type::array;
$QBit::Validator::Type::array::VERSION = '0.010';
use qbit;

use base qw(QBit::Validator::Type);

#order is important
my $OPTIONS = [
    {name => 'optional', required => TRUE},
    {name => 'size_min'},
    {name => 'size'},
    {name => 'size_max'},
    {name => 'all'},
    {name => 'contents'},
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

    if ($template->{$option}) {
        if (defined($data)) {
            unless (ref($data) eq 'ARRAY') {
                $qv->_add_error($template, gettext('Data must be ARRAY'), \@path_field);

                return FALSE;
            }
        } else {
            $qv->_add_ok(\@path_field);

            return FALSE;
        }
    } else {
        if (!defined($data)) {
            $qv->_add_error($template, gettext('Data must be defined'), \@path_field);

            return FALSE;
        } else {
            unless (ref($data) eq 'ARRAY') {
                $qv->_add_error($template, gettext('Data must be ARRAY'), \@path_field);

                return FALSE;
            }
        }
    }

    return TRUE;
}

sub size_min {
    my ($self, $qv, $data, $template, $option, @path_field) = @_;

    throw Exception::Validator gettext('Option "%s" must be positive number', $option)
      if !defined($template->{$option}) || $template->{$option} !~ /\A[0-9]+\z/;

    if (@$data < $template->{$option}) {
        $qv->_add_error($template, gettext('Data size "%s" less then "%s"', scalar(@$data), $template->{$option}),
            \@path_field);

        return FALSE;
    }

    return TRUE;
}

sub size {
    my ($self, $qv, $data, $template, $option, @path_field) = @_;

    throw Exception::Validator gettext('Key "%s" must be positive number', $option)
      if !defined($template->{$option}) || $template->{$option} !~ /\A[0-9]+\z/;

    unless (@$data == $template->{$option}) {
        $qv->_add_error($template, gettext('Data size "%s" not equal "%s"', scalar(@$data), $template->{$option}),
            \@path_field);

        return FALSE;
    }

    return TRUE;
}

sub size_max {
    my ($self, $qv, $data, $template, $option, @path_field) = @_;

    throw Exception::Validator gettext('Key "%s" must be positive number', $option)
      if !defined($template->{$option}) || $template->{$option} !~ /\A[0-9]+\z/;

    if (@$data > $template->{$option}) {
        $qv->_add_error($template, gettext('Data size "%s" more than "%s"', scalar(@$data), $template->{$option}),
            \@path_field);

        return FALSE;
    }

    return TRUE;
}

sub all {
    my ($self, $qv, $data, $template, $option, @path_field) = @_;

    throw Exception::Validator gettext('Options "all" and "contents" can not be used together')
      if exists($template->{$option}) && exists($template->{'contents'});

    throw Exception::Validator gettext('Option "%s" must be HASH')
      if !defined($template->{$option}) || ref($template->{$option}) ne 'HASH';

    my $num = 0;
    foreach (@$data) {
        my @path = (@path_field, $num);

        $qv->_validation($_, $template->{'all'}, undef, @path);

        return FALSE if $qv->has_error(\@path);

        $num++;
    }

    return TRUE;
}

sub contents {
    my ($self, $qv, $data, $template, $option, @path_field) = @_;

    throw Exception::Validator gettext('Option "%s" must be ARRAY', $option)
      if !defined($template->{$option}) || ref($template->{$option}) ne 'ARRAY';

    if (@$data != @{$template->{$option}}) {
        $qv->_add_error($template,
            gettext('Data size "%s" no equal "%s"', scalar(@$data), scalar(@{$template->{$option}})), \@path_field);

        return FALSE;
    }

    my $num = 0;
    foreach (@$data) {
        my @path = (@path_field, $num);

        $qv->_validation($_, $template->{$option}[$num], undef, @path);

        return FALSE if $qv->has_error(\@path);

        $num++;
    }

    return TRUE;
}

TRUE;
