package QBit::Validator::Type::array;
$QBit::Validator::Type::array::VERSION = '0.012';
use qbit;

use base qw(QBit::Validator::Type);

use Exception::Validator;
use Exception::Validator::FailedField;

#order is important
sub get_options_name {
    qw(type size_min size size_max all contents);
}

sub pre_process_template {
    my ($self, $template) = @_;

    throw Exception::Validator gettext('Options "all" and "contents" can not be used together')
      if exists($template->{'all'}) && exists($template->{'contents'});
}

sub type {
    return sub {
        throw gettext('Data must be ARRAY') unless ref($_[1]) eq 'ARRAY';

        return TRUE;
      }
}

sub size_min {
    my ($qv, $size_min) = @_;

    throw Exception::Validator gettext('Option "%s" must be positive number', 'size_min')
      if !defined($size_min) || $size_min !~ /\A[0-9]+\z/;

    return sub {
        throw FF gettext('Data size "%s" less then "%s"', scalar(@{$_[1]}), $size_min) if @{$_[1]} < $size_min;

        return TRUE;
    };
}

sub size {
    my ($qv, $size) = @_;

    throw Exception::Validator gettext('Option "%s" must be positive number', 'size')
      if !defined($size) || $size !~ /\A[0-9]+\z/;

    return sub {
        throw FF gettext('Data size "%s" not equal "%s"', scalar(@{$_[1]}), $size) unless @{$_[1]} == $size;

        return TRUE;
    };
}

sub size_max {
    my ($qv, $size_max) = @_;

    throw Exception::Validator gettext('Option "%s" must be positive number', 'size_max')
      if !defined($size_max) || $size_max !~ /\A[0-9]+\z/;

    return sub {
        throw FF gettext('Data size "%s" more than "%s"', scalar(@{$_[1]}), $size_max) if @{$_[1]} > $size_max;

        return TRUE;
    };
}

sub all {
    my ($qv, $template) = @_;

    my $parent       = $qv->parent // $qv;
    my $path_manager = $parent->path_manager();

    my $validator = QBit::Validator->new(
        template => $template,
        parent   => $parent,
        path     => $path_manager->get_absolute_path($path_manager->get_path_part('array', '%d'), $qv->path),
    );

    return sub {
        my $errors = [];

        my $num = 0;
        $path_manager->set_dynamic_part(\$num);
        foreach (@{$_[1]}) {
            unless ($validator->_validate($_)) {
                $errors->[$num] = $validator->get_errors;
            }

            $num++;
        }
        $path_manager->reset_dynamic_part();

        throw FF $errors if @$errors;

        return TRUE;
    };
}

sub contents {
    my ($qv, $templates) = @_;

    throw Exception::Validator gettext('Option "%s" must be ARRAY', 'contents')
      if !defined($templates) || ref($templates) ne 'ARRAY';

    my $parent       = $qv->parent // $qv;
    my $path_manager = $parent->path_manager;

    my $path = $qv->path;

    my @validators = ();
    my $i          = 0;
    foreach my $template (@$templates) {
        my $validator = QBit::Validator->new(
            template => $template,
            parent   => $parent,
            path     => $path_manager->get_absolute_path($path_manager->get_path_part('array', $i), $path),
        );

        push(@validators, $validator);

        $i++;
    }

    return sub {
        throw FF gettext('Data size "%s" no equal "%s"', scalar(@{$_[1]}), scalar(@validators))
          unless @{$_[1]} == @validators;

        my $errors = [];
        my $num    = 0;
        foreach (@{$_[1]}) {
            unless ($validators[$num]->_validate($_)) {
                $errors->[$num] = $validators[$num]->get_errors;
            }

            $num++;
        }

        throw FF $errors if @$errors;

        return TRUE;
    };
}

sub init {
    my ($self) = @_;

    $self->SUPER::init();

    foreach ($self->get_options_name) {
        $self->{$_} = \&$_;
    }
}

TRUE;
