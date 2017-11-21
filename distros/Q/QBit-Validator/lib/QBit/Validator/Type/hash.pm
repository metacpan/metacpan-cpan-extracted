package QBit::Validator::Type::hash;
$QBit::Validator::Type::hash::VERSION = '0.011';
use qbit;

use base qw(QBit::Validator::Type);

use Exception::Validator;

#order is important
my $OPTIONS = [
    {name => 'optional', required => TRUE},
    {name => 'deps'},
    {name => 'fields'},
    {name => 'one_of'},
    {name => 'any_of'},
    {name => 'extra',    required => TRUE},
];

sub _get_options {
    return clone($OPTIONS);
}

sub _get_options_name {
    return map {$_->{'name'}} @$OPTIONS;
}

sub optional {
    my ($self, $qv, $data, $template, $option, @path_field) = @_;

    if ($template->{$option}) {
        if (defined($data)) {
            unless (ref($data) eq 'HASH') {
                $qv->_add_error($template, gettext('Data must be HASH'), \@path_field);

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
            unless (ref($data) eq 'HASH') {
                $qv->_add_error($template, gettext('Data must be HASH'), \@path_field);

                return FALSE;
            }
        }
    }

    return TRUE;
}

sub deps {
    my ($self, $qv, $data, $template, $option, @path_field) = @_;

    throw Exception::Validator gettext('Option "%s" must be HASH', $option) unless ref($template->{$option}) eq 'HASH';

    my $no_error = TRUE;

    foreach my $field (keys(%{$template->{$option}})) {
        my @path = (@path_field, $field);

        if (exists($data->{$field})) {
            my $deps = $template->{$option}{$field};

            my ($dep_fields, $cases, $set_template);
            if (ref($deps) eq 'HASH') {
                throw Exception::Validator gettext('You must specify option "fields"')
                  unless exists($deps->{'fields'});

                $dep_fields = $deps->{'fields'};

                my @exists_options = grep {exists($deps->{$_})} qw(cases set_template);
                throw Exception::Validator gettext('You must specify option "cases" or "set_template"')
                  if @exists_options != 1;

                $cases        = $deps->{'cases'};
                $set_template = $deps->{'set_template'};
            } else {
                $dep_fields = $deps;
            }

            throw Exception::Validator gettext('You must specify the fields on which the field "%s"', $field)
              unless defined($dep_fields);

            $dep_fields = [$dep_fields] unless ref($dep_fields) eq 'ARRAY';

            my @dep_fields_with_errors = ();
            my $has_errors             = FALSE;
            foreach my $dep_field (@$dep_fields) {
                unless (exists($data->{$dep_field})) {
                    push(@dep_fields_with_errors, $dep_field);

                    next;
                }

                my @dep_path = (@path_field, $dep_field);

                $qv->_validation($data->{$dep_field}, $template->{'fields'}{$dep_field}, undef, @dep_path)
                  unless $qv->checked(\@dep_path);

                $has_errors = TRUE if $qv->has_error(\@dep_path);
            }

            if (@dep_fields_with_errors) {
                $qv->_add_error($template,
                    gettext('Key "%s" depends from: %s', $field, join(',', map {"\"$_\""} @dep_fields_with_errors)),
                    \@path);

                return FALSE;
            }

            if ($has_errors) {
                $no_error = FALSE;
                next;
            }

            if (defined($cases)) {
                throw Exception::Validator gettext('Option "%s" must be ARRAY', 'cases') if ref($cases) ne 'ARRAY';

                foreach my $case (@$cases) {
                    my $case_template =
                      {%{$case->[0]}, map {$_ => {skip => TRUE}} grep {!exists($case->[0]{$_})} @$dep_fields};

                    my $case_qv = $qv->new(
                        data => {map {$_ => $data->{$_}} @$dep_fields},
                        template => {type => 'hash', fields => $case_template}
                    );

                    unless ($case_qv->has_errors) {
                        $template->{'fields'}{$field} = $case->[1];

                        last;
                    }
                }
            }

            if (defined($set_template)) {
                throw Exception::Validator gettext('Option "%s" must be code', 'set_template')
                  if ref($set_template) ne 'CODE';

                try {
                    my $new_template = $set_template->($qv, $data);

                    if (defined($new_template) && ref($new_template) eq 'HASH') {
                        $template->{'fields'}{$field} = $new_template;
                    }
                }
                catch {
                    throw Exception::Validator gettext('Internal error');
                };
            }
        }
    }

    return $no_error;
}

sub fields {
    my ($self, $qv, $data, $template, $option, @path_field) = @_;

    my $no_error = TRUE;

    foreach my $field (keys(%{$template->{$option}})) {
        my @path = (@path_field, $field);

        if (!$template->{$option}{$field}{'optional'} && !exists($data->{$field})) {
            $qv->_add_error($template, gettext('Key "%s" required', $field), \@path);
        }

        $qv->_validation($data->{$field}, $template->{$option}{$field}, undef, @path)
          unless $qv->checked(\@path);

        $no_error = FALSE if $qv->has_error(\@path);
    }

    return $no_error;
}

sub extra {
    my ($self, $qv, $data, $template, $option, @path_field) = @_;

    my @extra_fields = grep {!$template->{'fields'}{$_}} keys(%$data);

    if (@extra_fields && !$template->{$option}) {
        $qv->_add_error($template, gettext('Extra fields: %s', join(', ', @extra_fields)), \@path_field);

        return FALSE;
    }

    return TRUE;
}

sub one_of {
    my ($self, $qv, $data, $template, $option, @path_field) = @_;

    throw Exception::Validator gettext('Option "%s" must be ARRAY', $option)
      if ref($template->{$option}) ne 'ARRAY';

    my $min_size = 2;

    throw Exception::Validator gettext('Option "%s" have size "%s", but expected size equal or more than "%s"',
        $option, scalar(@{$template->{$option}}), $min_size)
      if @{$template->{$option}} < $min_size;

    my @received_fields = ();
    foreach my $field (@{$template->{$option}}) {
        throw Exception::Validator gettext('Key "%s" do not use in option "fields"', $field)
          unless exists($template->{'fields'}{$field});

        push(@received_fields, $field) if exists($data->{$field});
    }

    unless (@received_fields == 1) {
        $qv->_add_error($template, gettext('Expected one key from: %s', join(', ', @{$template->{$option}})),
            \@path_field);

        return FALSE;
    }

    return TRUE;
}

sub any_of {
    my ($self, $qv, $data, $template, $option, @path_field) = @_;

    throw Exception::Validator gettext('Option "%s" must be ARRAY', $option)
      if ref($template->{$option}) ne 'ARRAY';

    my $min_size = 2;

    throw Exception::Validator gettext('Option "%s" have size "%s", but expected size equal or more than "%s"',
        $option, scalar(@{$template->{$option}}), $min_size)
      if @{$template->{$option}} < $min_size;

    my @received_fields = ();
    foreach my $field (@{$template->{$option}}) {
        throw Exception::Validator gettext('Key "%s" do not use in option "fields"', $field)
          unless exists($template->{'fields'}{$field});

        push(@received_fields, $field) if exists($data->{$field});
    }

    unless (@received_fields) {
        $qv->_add_error($template, gettext('Expected any keys from: %s', join(', ', @{$template->{$option}})),
            \@path_field);

        return FALSE;
    }

    return TRUE;
}

TRUE;
