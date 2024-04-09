#!/usr/bin/env perl

# PODNAME: synth-config-mojo.pl

use Mojolicious::Lite -signatures;

use Data::Dumper::Compact qw(ddc);
use Mojo::JSON qw(to_json);
use Mojo::File ();
use Mojo::Util qw(trim);
use Storable qw(store retrieve);

use lib map { "$ENV{HOME}/sandbox/$_/lib" } qw(Synth-Config); # local author library
use Synth::Config ();

use constant SETTINGS => './eg/public/settings/';

get '/' => sub ($c) {
  my $model  = $c->param('model');
  my $name   = $c->param('name');
  my $group  = $c->param('group');
  my $fields = $c->param('fields');
  my ($models, $names, $groups, $settings);
  $model  = trim($model)  if $model;
  $name   = trim($name)   if $name;
  $fields = trim($fields) if $fields;
  my $synth = Synth::Config->new(model => $model, verbose => 1);
  if ($model) {
    # TODO save the specs config file IN THE DATABASE please
    # get a specs config file for the synth model
    my $set_file = SETTINGS . $synth->model . '.dat';
    my $specs = -e $set_file ? retrieve($set_file) : undef;
    # get the known groups if there are specs
    $groups = $specs ? $specs->{group} : undef;
    # fetch the things!
    if ($group || $name || $fields) {
      my %parameters;
      $parameters{group} = $group if $group;
      $parameters{name}  = $name  if $name;
      if ($fields) {
        my @fields = split /\s*,\s*/, $fields;
        for my $f (@fields) {
          my ($key, $val) = split /\s*:\s*/, $f;
          $parameters{$key} = $val;
        }
      }
      $settings = $synth->search_settings(%parameters);
    }
    elsif ($synth->model) {
      $settings = $synth->recall_all;
    }
    $names = $synth->recall_names;
  }
  $models = $synth->recall_models;
  for my $m (@$models) {
    $m =~ s/_/ /g;
  }
  $c->render(
    template => 'index',
    model    => $model,
    models   => $models,
    name     => $name,
    names    => $names,
    group    => $group,
    groups   => $groups,
    fields   => $fields,
    settings => $settings,
  );
} => 'index';

get '/model' => sub ($c) {
  my $model  = $c->param('model');
  my $specs  = $c->param('specs');
  my $groups = $c->param('groups');
  my $group_list = $groups ? [ split /\s*,\s*/, $groups ] : undef;
  $c->render(
    template   => 'model',
    model      => $model,
    specs      => $specs,
    groups     => $groups,
    group_list => $group_list,
  );
} => 'model';
post '/model' => sub ($c) {
  my $v = $c->validation;
  $v->required('model');
  $v->required('groups');
  $v->optional('clone');
  if ($v->failed->@*) {
    $c->flash(error => 'Could not update model');
    return $c->redirect_to('model');
  }
  my $synth = Synth::Config->new(model => $v->param('model'));
  my $group_params = $c->every_param('group');
  if (@$group_params) {
    my $model_file = SETTINGS . $synth->model . '.dat';
    my @groups = split /\s*,\s*/, $v->param('groups');
    my $specs = -e $model_file ? retrieve($model_file) : undef;
    my $i = 0;
    for my $g (@groups) {
      $specs->{parameter}{$g} = [ split /\s*,\s*/, $group_params->[$i] ];
      $i++;
    }
    if ($v->param('clone')) {
      $synth = Synth::Config->new(model => $v->param('clone'));
      $model_file = SETTINGS . $synth->model . '.dat';
      store($specs, $model_file);
      $c->flash(message => 'Clone model successful');
      return $c->redirect_to($c->url_for('index')->query(model => $v->param('clone')));
    }
    else {
      store($specs, $model_file);
      $c->flash(message => 'Update parameters successful');
      return $c->redirect_to($c->url_for('index')->query(model => $v->param('model')));
    }
  }
  else {
    my $init_file = Mojo::File->new(SETTINGS . 'initial.set');
    my $specs = -e $init_file ? do $init_file : undef;
    unless ($specs) {
      $c->flash(error => 'Invalid init file');
      return $c->redirect_to('model');
    }
    $specs->{group} = [ split /\s*,\s*/, $v->param('groups') ];
    $specs->{parameter}{$_} = [] for $specs->{group}->@*;
    my $model_file = SETTINGS . $synth->model . '.dat';
    store($specs, $model_file);
    $c->flash(message => 'Add model successful');
    return $c->redirect_to($c->url_for('model')->query(model => $v->param('model'), groups => $v->param('groups')));
  }
} => 'update_model';
get '/edit_model' => sub ($c) {
  my $v = $c->validation;
  $v->required('model');
  $v->optional('clone');
  if ($v->failed->@*) {
    $c->flash(error => 'Could not edit model');
    return $c->redirect_to($c->url_for('index')->query(model => $v->param('model')));
  }
  my $synth = Synth::Config->new(model => $v->param('model'));
  my $model_file = SETTINGS . $synth->model . '.dat';
  my $specs = -e $model_file ? retrieve($model_file) : undef;
  my $groups = exists $specs->{group} ? join ',', $specs->{group}->@* : undef;
  $c->render(
    template   => 'edit_model',
    model      => $v->param('model'),
    groups     => $groups,
    group_list => $specs->{group},
    specs      => $specs->{parameter},
    clone      => $v->param('clone'),
  );
} => 'edit_model';

get '/remove' => sub ($c) {
  my $v = $c->validation;
  $v->optional('id');
  $v->optional('name');
  $v->optional('model');
  $v->optional('group');
  if ($v->failed->@*) {
    $c->flash(error => 'Remove failed');
    return $c->redirect_to('index');
  }
  my $synth = Synth::Config->new(model => $v->param('model'));
  if ($v->param('id')) {
    $synth->remove_setting(id => $v->param('id'));
    $c->flash(message => 'Remove setting successful');
    return $c->redirect_to($c->url_for('index')->query(model => $v->param('model'), name => $v->param('name'), group => $v->param('group')));
  }
  elsif ($v->param('name') && !($v->param('id'))) {
    $synth->remove_settings(name => $v->param('name'));
    $c->flash(message => 'Remove named settings successful');
    return $c->redirect_to($c->url_for('index')->query(model => $v->param('model')));
  }
  elsif ($synth->model && !$v->param('name')) {
    $synth->remove_model;
    my $model_file = Mojo::File->new(SETTINGS . $synth->model . '.dat');
    $model_file->remove;
    $c->flash(message => 'Remove model successful');
    return $c->redirect_to('index');
  }
} => 'remove';

get '/edit_setting' => sub ($c) {
  my $id         = $c->param('id');
  my $name       = $c->param('name');
  my $model      = $c->param('model');
# TODO gather these keys from the init.set file
  my $group      = $c->param('group');
  my $parameter  = $c->param('parameter');
  my $control    = $c->param('control');
  my $group_to   = $c->param('group_to');
  my $param_to   = $c->param('param_to');
  my $bottom     = $c->param('bottom');
  my $top        = $c->param('top');
  my $value      = $c->param('value');
  my $unit       = $c->param('unit');
  my $is_default = $c->param('is_default');
  $model = trim($model) if $model;
  $name  = trim($name)  if $name;
  my $synth = Synth::Config->new(model => $model);
  # get a specs config file for the synth model
  my $set_file = SETTINGS . $synth->model . '.dat';
  my $specs = -e $set_file ? retrieve($set_file) : undef;
  unless ($specs) {
    $c->flash(error => 'No known model');
    return $c->redirect_to('index');
  }
  my $models = $synth->recall_models;
  for my $m (@$models) {
    $m =~ s/_/ /g;
  }
  my $selected = {
    group      => $group,
    parameter  => $parameter,
    control    => $control,
    group_to   => $group_to,
    param_to   => $param_to,
    bottom     => $bottom,
    top        => $top,
    value      => $value,
    unit       => $unit,
    is_default => $is_default,
  };
  $c->render(
    template => 'edit_setting',
    specs    => $specs,
    id       => $id,
    name     => $name,
    model    => $model,
    models   => $models,
    selected => $selected,
  );
} => 'edit_setting';

post '/update_setting' => sub ($c) {
  my $v = $c->validation;
  $v->required('name');
  $v->required('model');
# TODO gather these keys from the *.set file
  $v->required('group');
  $v->required('parameter');
  $v->required('control');
  $v->optional('group_to');
  $v->optional('param_to');
  $v->optional('bottom');
  $v->optional('top');
  $v->optional('value');
  $v->optional('unit');
  $v->optional('is_default');
  $v->optional('id');
  if ($v->failed->@*) {
    $c->flash(error => 'Could not update setting');
    return $c->redirect_to('edit_setting');
  }
  my $model = trim $v->param('model') if $v->param('model');
  my $name  = trim $v->param('name')  if $v->param('name');
  my $value = trim $v->param('value') if defined $v->param('value');
  my $synth = Synth::Config->new(model => $model);
  # get a specs config file for the synth model
  my $set_file = SETTINGS . $synth->model . '.dat';
  my $specs = -e $set_file ? retrieve($set_file) : undef;
  my $id = $synth->make_setting(
    id         => $v->param('id'),
    name       => $name,
    group      => $v->param('group'),
    parameter  => $v->param('parameter'),
    control    => $v->param('control'),
    group_to   => $v->param('group_to'),
    param_to   => $v->param('param_to'),
    bottom     => $v->param('bottom'),
    top        => $v->param('top'),
    value      => $value,
    unit       => $v->param('unit'),
    is_default => $v->param('is_default'),
  );
  $c->flash(message => 'Update setting successful');
  $c->redirect_to($c->url_for('edit_setting')->query(
    id         => $id,
    name       => $v->param('name'),
    model      => $v->param('model'),
    group      => $v->param('group'),
    parameter  => $v->param('parameter'),
    control    => $v->param('control'),
    group_to   => $v->param('group_to'),
    param_to   => $v->param('param_to'),
    bottom     => $v->param('bottom'),
    top        => $v->param('top'),
    value      => $v->param('value'),
    unit       => $v->param('unit'),
    is_default => $v->param('is_default'),
  ));
} => 'update_setting';

helper to_json => sub ($c, $data) {
  return to_json $data;
};

helper build_edit_url => sub ($c, $model, $id, $set) {
  my $edit_url = $c->url_for('edit_setting')->query(
    $id ? (id => $id) : (),
    model      => $model,
    name       => $set->{name},
# TODO gather these keys from the *.set file
    group      => $set->{group},
    parameter  => $set->{parameter},
    control    => $set->{control},
    group_to   => $set->{group_to},
    param_to   => $set->{param_to},
    bottom     => $set->{bottom},
    top        => $set->{top},
    value      => $set->{value},
    unit       => $set->{unit},
    is_default => $set->{is_default},
  );
  return $edit_url;
};

app->secrets(['yabbadabbadoo']);

app->start;

__DATA__

@@ index.html.ep
% layout 'default';
<p></p>
<form action="<%= url_for('index') %>" method="get">
<div class="row">
  <div class="col">
    <select name="model" id="model" class="form-select" onchange="this.form.submit();" required>
      <option value="">Model name...</option>
% for my $m (@$models) {
      <option value="<%= $m %>" <%= $models && $model && lc($m) eq lc($model) ? 'selected' : '' %>><%= ucfirst $m %></option>
% }
    </select>
  </div>
  <div class="col">
    <select name="name" id="name" class="form-select" onchange="this.form.submit();">
      <option value="">Setting name...</option>
% for my $n (@$names) {
      <option value="<%= $n %>" <%= $names && $name && $n eq $name ? 'selected' : '' %>><%= ucfirst $n %></option>
% }
    </select>
  </div>
  <div class="col">
    <select name="group" id="group" class="form-select" onchange="this.form.submit();">
      <option value="">Group...</option>
% for my $g (@$groups) {
      <option value="<%= $g %>" <%= $group && $g eq $group ? 'selected' : '' %>><%= ucfirst $g %></option>
% }
    </select>
  </div>
</div>
<p></p>
<div class="row">
  <div class="col">
    <input type="text" name="fields" id="fields" value="<%= $fields %>" class="form-control" placeholder="Search field1:value1, field2:value2, etc.">
  </div>
</div>
<p></p>
<div class="row">
  <div class="col">
    <button type="submit" id="search" class="btn btn-primary"><i class="fa-solid fa-magnifying-glass"></i> Search</button>
    <a href="<%= url_for('model') %>" class="btn btn-success" id="new_model"><i class="fa-solid fa-database"></i> New model</a>
% if ($model) {
    <a href="<%= url_for('edit_setting')->query(model => $model, name => $name, group => $group) %>" id="new_setting" class="btn btn-success"><i class="fa-solid fa-plus"></i> New setting</a>
%   if ($name) {
    <a href="<%= url_for('remove')->query(model => $model, name => $name) %>" id="remove_name" class="btn btn-danger" onclick="if(!confirm('Remove <%= $name %> settings?')) return false;"><i class="fa-solid fa-trash-can"></i> Remove settings</a>
%   }
% }
  </div>
</div>
</form>
% if ($settings && @$settings) {
<p></p>
<table class="table table-hover">
<thead>
  <tr>
    <th scope="col">Edit</th>
    <th scope="col">Setting name</th>
    <th scope="col">Group</th>
    <th scope="col">Param</th>
    <th scope="col">Control</th>
    <th scope="col">Value</th>
  </tr>
</thead>
<tbody>
%   for my $setting (@$settings) {
%     my $id = $setting->{id};
%     my $edit_url = build_edit_url($model, $id, $setting);
<tr>
  <td><a href="<%= $edit_url %>" class="btn btn-sm btn-outline-secondary"><i class="fa-solid fa-pencil"></i></a></td>
  <td><%= $setting->{name} %></td>
  <td><%= $setting->{group} %></td>
  <td><%= $setting->{parameter} %></td>
  <td><i><%= $setting->{control} %></i></td>
  <td>
%     if ($setting->{group_to}) {
    <%= $setting->{group_to} %> <%= $setting->{param_to} %>
%     }
%     if ($setting->{value}) {
    <%= $setting->{value} %> <%= $setting->{unit} %>
%     }
  </td>
</tr>
%   }
</table>
% } elsif (!$model) {
<p></p>
<table class="table table-hover">
<thead>
  <tr>
    <th scope="col">Edit &nbsp; Model name</th>
  </tr>
</thead>
<tbody>
%   for my $m (@$models) {
<tr>
  <td><a href="<%= url_for('edit_model')->query(model => $m) %>" class="btn btn-sm btn-outline-secondary"><i class="fa-solid fa-pencil"></i></a> &nbsp; <%= ucfirst $m %></td>
</tr>
%   }
</table>
% }


@@ model.html.ep
% layout 'default';
<p></p>
<form action="<%= url_for('update_model') %>" method="post">
<div class="row">
  <div class="col">
    <input type="text" name="model" id="model" value="<%= $model %>" class="form-control" placeholder="Model name" required>
  </div>
</div>
<p></p>
<div class="row">
  <div class="col">
    <input type="text" name="groups" id="groups" value="<%= $groups %>" class="form-control" placeholder="group1, group2, etc." required>
  </div>
</div>
<p></p>
<div class="row">
  <div class="col">
% unless ($group_list) {
    <button type="submit" id="new_model" class="btn btn-primary"><i class="fa-solid fa-plus"></i> Add model</button>
% }
    <a href="<%= url_for('index') %>" id="cancel" class="btn btn-warning"><i class="fa-solid fa-xmark"></i> Cancel</a>
  </div>
</div>
</form>
% if ($group_list) {
<p></p>
<form action="<%= url_for('update_model') %>" method="post">
  <input type="hidden" name="model" value="<%= $model %>">
  <input type="hidden" name="groups" value="<%= $groups %>">
%   for my $g (@$group_list) {
  <input type="text" name="group" id="<%= $g %>" class="form-control" placeholder="<%= $g %> parameter1, param2, etc.">
  <p></p>
%   }
  <button type="submit" class="btn btn-primary"><i class="fa-solid fa-plus"></i> Add parameters</button>
</form>
% }


@@ edit_model.html.ep
% layout 'default';
<p></p>
<form action="<%= url_for('update_model') %>" method="post">
<div class="row">
  <div class="col">
    <label for="model">Model:</label>
    <input type="hidden" name="groups" value="<%= $groups %>">
% if ($clone) {
    <input type="hidden" name="model" value="<%= $model %>">
    <input type="text" name="clone" id="clone" class="form-control" required>
% } else {
    <input type="text" name="model" id="model" value="<%= $model %>" class="form-control" disabled readonly>
% }
  </div>
</div>
<p></p>
<b>Groups</b>:
<hr>
% for my $g (@$group_list) {
  <label for="<%= $g %>"><b><%= ucfirst $g %></b>:</label>
  <input type="text" name="group" id="<%= $g %>" value="<%= join ',', $specs->{$g}->@* %>" class="form-control" placeholder="<%= $g %> parameter1, param2, etc.">
  <p></p>
% }
  <div class="row">
    <div class="col">
% if ($clone) {
      <button type="submit" class="btn btn-primary"><i class="fa-solid fa-plus"></i> New model</button>
% } else {
      <button type="submit" class="btn btn-primary"><i class="fa-solid fa-arrow-rotate-right"></i> Update model</button>
      <a href="<%= url_for('remove')->query(model => $model) %>" id="remove_model" class="btn btn-danger" onclick="if(!confirm('Remove model?')) return false;"><i class="fa-solid fa-trash-can"></i> Remove model</a>
      <a href="<%= url_for('edit_model')->query(model => $model, clone => 1) %>" id="clone_model" class="btn btn-success"><i class="fa-solid fa-copy"></i> Clone</a>
% }
      <a href="<%= url_for('index')->query(model => $model) %>" id="cancel" class="btn btn-warning"><i class="fa-solid fa-xmark"></i> Cancel</a>
    </div>
  </div>
</form>


@@ edit_setting.html.ep
% layout 'default';
<p></p>
<form action="<%= url_for('update_setting') %>" method="post">
  <input type="hidden" name="id" value="<%= $id %>">
<div class="row">
  <div class="col">
    <select name="model" id="model" class="form-select" required>
      <option value="">Model name...</option>
% for my $m (@$models) {
      <option value="<%= $m %>" <%= $models && $model && lc($m) eq lc($model) ? 'selected' : '' %>><%= ucfirst $m %></option>
% }
    </select>
  </div>
  <div class="col">
    <input type="text" name="name" id="name" value="<%= $name %>" class="form-control" placeholder="Setting name" required>
  </div>
</div>
<p></p>
<div class="row">
  <div class="col">
% my $j = 0;
% for my $key ($specs->{order}->@*) {
%   $j++;
%   if ($j != 1) {
%     unless ($key eq 'parameter' || $key eq 'param_to' || $key eq 'top' || $key eq 'unit') {
<div class="row">
%     }
  <div class="col">
%   }
%   if ($key eq 'value') {
    <input type="text" name="<%= $key %>" id="<%= $key %>" value="<%= $selected->{value} %>" class="form-control" placeholder="Setting value">
%   } elsif ($key eq 'is_default') {
    Is default: &nbsp;
    <div class="form-check form-check-inline">
      <input class="form-check-input" type="radio" name="<%= $key %>" id="is_default_true" value="1" <%= $selected->{is_default} ? 'checked' : '' %>>
      <label class="form-check-label" for="is_default_true">True</label>
    </div>
    <div class="form-check form-check-inline">
      <input class="form-check-input" type="radio" name="<%= $key %>" id="is_default_false" value="0" <%= $selected->{is_default} ? '' : 'checked' %>>
      <label class="form-check-label" for="is_default_false">False</label>
    </div>
%   } else {
    <select name="<%= $key %>" id="<%= $key %>" class="form-select">
      <option value=""><%= ucfirst $key %>...</option>
%   my $my_key = $key eq 'group_to' ? 'group' : $key;
%   my @things = $key eq 'parameter' ? ($selected->{parameter}) : $key eq 'param_to' ? ($selected->{param_to}) : $specs->{$my_key}->@*;
%     for my $i (@things) {
%       next if !defined($i) || $i eq 'none' || $i eq '';
      <option value="<%= $i %>" <%= defined $selected->{$key} && $i eq $selected->{$key} ? 'selected' : '' %>><%= ucfirst $i %></option>
%     }
    </select>
%   }
%   if ($j != $specs->{order}->@*) {
  </div>
%     unless ($key eq 'group' || $key eq 'group_to' || $key eq 'bottom' || $key eq 'value') {
</div>
<p id="<%= $key . '_p' %>"></p>
%     }
%   }
% }
  </div>
</div>
  <p></p>
% if ($id) {
  <button type="submit" class="btn btn-primary"><i class="fa-solid fa-arrow-rotate-right"></i> Update</button>
  <a href="<%= url_for('remove')->query(id => $id, model => $model, name => $name, group => $selected->{group}) %>" id="remove" class="btn btn-danger" onclick="if(!confirm('Remove setting <%= $id %>?')) return false;"><i class="fa-solid fa-trash-can"></i> Remove</a>
% my $edit_url = build_edit_url($model, '', { name => $name, %$selected });
  <a href="<%= $edit_url %>" id="clone_setting" class="btn btn-success"><i class="fa-solid fa-copy"></i> Clone</a>
  <a href="<%= url_for('edit_setting')->query(model => $model, name => $name, group => $selected->{group}) %>" id="new_setting" class="btn btn-success"><i class="fa-solid fa-plus"></i> New</a>
% } else {
  <button type="submit" class="btn btn-primary"><i class="fa-solid fa-plus"></i> Submit</button>
% }
  <a href="<%= url_for('index')->query(model => $model, name => $name, group => $selected->{group}) %>" id="cancel" class="btn btn-warning"><i class="fa-solid fa-xmark"></i> Cancel</a>
</form>
<script>
$(document).ready(function() {
  function populate (group, param) {
    const paramUcfirst = param.charAt(0).toUpperCase() + param.substring(1) + '...';
    const selected = $("select#" + group).find(":selected").val();
    const dropdown = $("select#" + param);
    const json = '<%= to_json $specs->{parameter} %>'.replace(/&quot;/g, '"');
    const params = JSON.parse(json);
    const obj = params[selected];
    dropdown.empty();
    dropdown.append($('<option></option>').val("").text(paramUcfirst));
    obj.forEach((i) => {
      let text = i.replace(/-/g, ' ');
      text = text.charAt(0).toUpperCase() + text.substring(1);
      dropdown.append($('<option></option>').val(i).text(text));
    });
  }
  function toggle_patch (selected) {
    if (selected === 'patch') {
      $('label[for="group_to"]').show();
      $("#group_to").show();
      $("#group_to_p").show();
      $('label[for="param_to"]').show();
      $("#param_to").show();
      $("#param_to_p").show();
      $("#bottom").val($("#bottom option:first").val());
      $('label[for="bottom"]').hide();
      $("#bottom").hide();
      $("#bottom_p").hide();
      $("#top").val($("#top option:first").val());
      $('label[for="top"]').hide();
      $("#top").hide();
      $("#top_p").hide();
      $("#value").val('');
      $('label[for="value"]').hide();
      $("#value").hide();
      $("#value_p").hide();
      $("#unit").val($("#unit option:first").val());
      $('label[for="unit"]').hide();
      $("#unit").hide();
      $("#unit_p").hide();
    }
    else {
      $("#group_to").val($("#group_to option:first").val());
      $('label[for="group_to"]').hide();
      $("#group_to").hide();
      $("#group_to_p").hide();
      $("#param_to").val($("#param_to option:first").val());
      $('label[for="param_to"]').hide();
      $("#param_to").hide();
      $("#param_to_p").hide();
      $('label[for="bottom"]').show();
      $("#bottom").show();
      $("#bottom_p").show();
      $('label[for="top"]').show();
      $("#top").show();
      $("#top_p").show();
      $('label[for="value"]').show();
      $("#value").show();
      $("#value_p").show();
      $('label[for="unit"]').show();
      $("#unit").show();
      $("#unit_p").show();
    }
  }
  $("select#group").on('change', function() {
    populate("group", "parameter");
  });
  $("select#group_to").on('change', function() {
    populate("group_to", "param_to");
  });
  $("select#control").on('change', function() {
    const selected = $("select#control").find(":selected").val();
    toggle_patch(selected);
  });
  if ('<%= $selected->{control} %>' === 'patch') {
    toggle_patch('patch');
  }
  else {
    toggle_patch('not-patch');
  }
  if ('<%= $selected->{group} %>') {
    populate("group", "parameter");
    $("#parameter").val('<%= $selected->{parameter} %>');
  }
  if ('<%= $selected->{group_to} %>') {
    populate("group_to", "param_to");
    $("#param_to").val('<%= $selected->{param_to} %>');
  }
});
</script>


@@ layouts/default.html.ep
% title 'Synth::Config';
<!DOCTYPE html>
<html lang="en">
  <head>
    <title><%= title %></title>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.0.2/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-EVSTQN3/azprG1Anm3QDgpJLIm9Nao0Yz1ztcQTwFspd3yD65VohhpuuCOmLASjC" crossorigin="anonymous">
    <link href="/css/fontawesome.css" rel="stylesheet">
    <link href="/css/solid.css" rel="stylesheet">
    <script src="https://cdn.jsdelivr.net/npm/jquery@3.7.0/dist/jquery.min.js"></script>
    <style>
      a:hover, a:visited, a:link, a:active { text-decoration: none; }
    </style>
  </head>
  <body>
    <div class="container">
      <p></p>
% if (flash('error')) {
    %= tag h3 => (style => 'color:red') => flash('error')
% }
% if (flash('message')) {
    %= tag h3 => (style => 'color:green') => flash('message')
% }
      <h1><a href="<%= url_for('index') %>"><%= title %></a></h1>
      <%= content %>
      <p></p>
      <div id="footer" class="text-muted small">
        <hr>
        Copyright © 2023 All rights reserved
        <br>
        Built by <a href="http://gene.ology.net/">Gene</a>
        with <a href="https://www.perl.org/">Perl</a> and
        <a href="https://mojolicious.org/">Mojolicious</a>
      </div>
      <p></p>
    </div>
  </body>
</html>

