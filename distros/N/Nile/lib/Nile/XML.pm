#   Copyright Infomation
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Author : Dr. Ahmed Amin Elsheshtawy, Ph.D.
# Website: https://github.com/mewsoft/Nile, http://www.mewsoft.com
# Email  : mewsoft@cpan.org, support@mewsoft.com
# Copyrights (c) 2014-2015 Mewsoft Corp. All rights reserved.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
package Nile::XML;

our $VERSION = '0.55';
our $AUTHORITY = 'cpan:MEWSOFT';

=pod

=encoding utf8

=head1 NAME

Nile::XML - XML file manager.

=head1 SYNOPSIS
        
    # get a reference to the framework xml object.
    $xml = $self->app->xml;

    # get a reference to a new xml object.
    $xml = $self->app->xml->new;

    # keep sort order when reading and writing the xml file data. default is off.
    #$xml->keep_order(1);

    # load xml file
    $xml->load("path/to/xml/file.xml");

    # load and append another xml file to the same object
    $xml->load("path/to/xml/another.xml");

    # get value of email tag <email>ahmed@mewsoft.com</email>
    say $xml->get('email');

    # get tag value, if not found return the provided default value.
    $var = $xml->get($name, $default);

    # get tag attribute of email tag <email status='expired'>ahmed@mewsoft.com</email>
    # The prefix '-' is added on every attribute's name.
    say $xml->get('email')->{'-status'};

    # if an element has both of a text node and attributes or both of a text node and other child nodes,
    # value of a text node is moved to #text like child nodes.
    say $xml->get('email')->{'#text'};

    # get value of email tag inside other tags
    # <users><user><contact><email>ahmed@mewsoft.com</email></contact></user></users>
    say $xml->get('users/user/contact/email');

    # automatic getter support
    $email = $xml->email; # same as $xml->get('email');

    # automatic setter support
    $xml->email('ahmed@mewsoft.com'); # $xml->set('email', 'ahmed@mewsoft.com');

    # set value of email tag <email></email>
    $xml->set('email', 'ahmed@mewsoft.com');

    # set value of email tag inside other tags
    # <users><user><contact><email></email></contact></user></users>
    $xml->set('users/user/contact/email', 'ahmed@mewsoft.com');
    
    # access variables as a hash tree
    $xml->var->{accounts}->{users}->{admin}->{username} = 'admin';

    # get a list of tags values.
    ($users, $views, $items) = $xml->list( qw( users views items ) );

    # delete xml tags by names
    $xml->delete(@names);

    # delete entire xml object contents in memory
    $xml->clear();

    # load and append another xml file to the object
    $xml->add_file($another_file);

    # updated the provided tags and save changes to the file
    $xml->update(%tags);

    # Save changes to the output file. If no file name just update the loaded file name.
    $xml->save($file);

    # load xml file content and return it as a hash, not added to the object
    %xml_hash = $xml->get_file($file);
    say $xml_hash{root}{config}{database}{user};

    # load xml file content and return it as a hash ref, not added to the object
    $xml_hash_ref = $xml->get_file($file);
    say $xml_hash_ref->{root}->{config}->{database}->{user};

    # get a new xml object
    #my $xml_other = $xml->object;
    #my $xml_other = $xml->new;
    
    # load and manage another xml files separately
    #$xml_other->load("xmlfile");

=head1 DESCRIPTION

Nile::XML - XML file manager.

Parsing and writing XML files into a hash tree object supports sorted order and build on the module L<XML::TreePP>.

=cut

use Nile::Base;
use XML::TreePP;
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 xml()
    
    # get a new XML::TreePP object.
    $xml_obj = $xml->xml(@names);
    # then you can use $xml_obj as XML::TreePP object.

Returns a new L<XML::TreePP> object.

=cut

has 'xml' => (
    is          => 'rw',
    default => sub {XML::TreePP->new()},
  );


=head2 file()
    
    # set output file name for saving
    $xml->file($file);

    # get output file name
    $file = $xml->file();

Get and set the output xml file name used when saving or updating.

=cut

has 'file' => (
    is          => 'rw',
  );

=head2 encoding()
    
    # get encoding used to read/write the file, default is 'UTF-8'.
    $encoding = $xml->encoding();
    
    # set encoding used to read/write the file, default is 'UTF-8'.
    $xml->encoding('UTF-8');

Get and set encoding used to read/write the xml file The default encoding is 'UTF-8'.

=cut

has 'encoding' => (
    is          => 'rw',
    default => 'UTF-8',
  );

=head2 indent()
    
    # get indent, default 4.
    $indent = $xml->indent();
    
    # set indent.
    $xml->indent(6);

This makes the output more human readable by indenting appropriately.

=cut

has 'indent' => (
    is          => 'rw',
    default => 4,
  );

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub AUTOLOAD {
    my ($self) = shift;

    my ($class, $method) = our $AUTOLOAD =~ /^(.*)::(\w+)$/;

    if ($self->can($method)) {
        return $self->$method(@_);
    }

    if (@_) {
        $self->set($method, $_[0]);
    }
    else {
        return $self->get($method);
    }
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 load()
    
    # get xml object
    $xml = $self->app->xml->new;

    # load xml file
    $xml->load($file);
    
    # load and append another xml file
    $xml->load($another);

Loads xml files to the object in memory. This will not clear any previously loaded files. To will add files.
This method can be chained C<$xml->load($file)->add_file($another_file)>;

=cut

sub load {
    
    my ($self, $file) = @_;
    
    $file .= ".xml" unless ($file =~ /\.[^.]*$/i);
    ($file && -f $file) || $self->app->abort("Error reading file '$file'. $!");
    
    my $xml = $self->xml->parsefile($file);

    #$self->{vars} ||= +{};
    #$self->{vars} = {%{$self->{vars}}, %$xml};
    
    if ($self->{vars}) {
        while (my ($k, $v) = each %{$xml}) {
            $self->{vars}->{$k} = $v;
        }
    }
    else {
        $self->{vars} = $xml;
        $self->file($file);
    }

    $self;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 keep_order()
    
    # keep sort order when loading and saving the file. default is off.
    $xml->keep_order(1);
    
    # turn it off
    $xml->keep_order(0);

This option keeps the order for each element appeared in XML. L<Tie::IxHash> module is required.
This makes parsing performance slow (about 100% slower than default). But sometimes it is required
for example when loading url routes files, it is important to keep routes in the same sorted order in the files.

=cut

sub keep_order {
    my ($self, $status) = @_;
    # This option keeps the order for each element appeared in XML. Tie::IxHash module is required.
    # This makes parsing performance slow. (about 100% slower than default)
    $self->xml->set(use_ixhash => $status);
    return $self;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 get()
    
    # get value of email tag <email>ahmed@mewsoft.com</email>
    say $xml->get('email'); # returns ahmed@mewsoft.com

    # get tag value, if not found return the optional provided default value.
    $var = $xml->get($name, $default);

    # get value of email tag inside other tags
    # <users><user><contact><email>ahmed@mewsoft.com</email></contact></user></users>
    say $xml->get('users/user/contact/email'); # returns ahmed@mewsoft.com
    
    # automatic getter support
    $email = $xml->email; # same as $xml->get('email');

    # get list
    # <lang><file>general</file><file>contact</file><file>register</file></lang>
    @files = $xml->get("lang/file");

Returns xml tag value, if not found returns the optional provided default value.

=cut

sub get {
    
    my ($self, $path, $default) = @_;
    
    my $value;

    if ($path !~ /\//) {
        $value = exists $self->{vars}->{$path}? $self->{vars}->{$path} : $default;
    }
    else {
        $path =~ s/^\/+|\/+$//g;
        my @path = split /\//, $path;
        my $v = $self->{vars};
        
        while (my $k = shift @path) {
            if (!exists $v->{$k}) {
                $v = $default;
                last;
            }
             $v = $v->{$k};
        }
        $value = $v;
    }
    
    if (ref($value) eq "ARRAY" ) {
        return @{$value};
    }
    elsif (ref($value) eq "HASH" ) {
        #return %{$value};
        return $value;
    }
    else {
        return $value;
    }
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 set()
    
    # set tag value
    $xml->set('email', 'ahmed@mewsoft.com');

    # set a group of tags
    $xml->set(%tags);

    # set value of nested tags
    # <users><user><contact><email>ahmed@mewsoft.com</email></contact></user></users>
    $xml->set('users/user/contact/email', 'ahmed@mewsoft.com');

Sets tags values.

=cut

sub set {

    my ($self, %vars) = @_;
    #map { $self->{vars}->{$_} = $vars{$_}; } keys %vars;
    
    my ($path, $value, @path, $k, $v, $key);

    while ( ($path, $value) = each %vars) {

        #if ($path !~ /\//) {
        #   $self->{vars}->{$path} = $value;
        #   next;
        #}
        
        # path /accounts/users/admin
        $path =~ s/^\/+|\/+$//g;
        @path = split /\//, $path;
        $v = $self->{vars};
        
        # $key = admin, @path= (accounts, users)
        $key = pop @path;

        while ($k = shift @path) {
            if (!exists $v->{$k}) {
                $v->{$k} = +{};
            }
             $v = $v->{$k};
        }
        
        # $v = $self->{vars}->{accounts}->{users}, $key = admin
        $v->{$key} = $value;
    }

    $self;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 list()
    
    # get a list of tags values.
    @values = $xml->list(@names);
    ($users, $views, $items) = $xml->list( qw( users views items ) );

Returns a list of tags values.

=cut

sub list {
    my ($self, @n) = @_;
    my @v;
    push @v, $self->get($_) for @n;
    return @v
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 var()
    
    # get a hash ref to the xml data for direct access.
    $xml_ref = $xml->var();
    $xml_ref->{root}->{users}->{user}->{admin} = 'username';
    say $xml_ref->{root}->{users}->{user}->{admin};

Returns a hash reference to the in memory xml data.

=cut

sub var {
    my ($self) = @_;
    return $self->{vars};
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 delete()
    
    # delete tags from memory, changes will apply when saving file.
    $xml->delete(@names);

Delete a list of tags. Tags will be deleted from the object and memory only and will apply
when updating or saving the file.

=cut

sub delete {
    my ($self, @vars) = @_;
    delete $self->{vars}->{$_} for @vars;
    $self;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 clear()
    
    # delete entire xml object data.
    $xml->clear();

Completely clears all loaded xml data from  memory. This does not apply to the file until file is
updated or saved.

=cut

sub clear {
    my ($self) = @_;
    $self->{vars} = +{};
    $self;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 update()
    
    # save a list of variables and update the file.
    $xml->update(%vars);

Set list of variables and save to the output file immediately.

=cut

sub update {
    my ($self, %vars) = @_;
    $self->set(%vars);
    $self->save();
    $self;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 save()
    
    # write the output file.
    $xml->save($file);

Save changes to the output file. If no file name just update the loaded file name.

=cut

sub save {
    my ($self, $file) = @_;
    $self->xml->set(indent => $self->indent);
    $self->xml->writefile($file || $self->file, $self->{vars}, $self->encoding);
    $self;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 get_file()
    
    # load xml file content and return it as a hash, not added to the object
    %xml_hash = $xml->get_file($file);
    say $xml_hash{root}{config}{database}{user};

    # load xml file content and return it as a hash ref, not added to the object
    $xml_hash_ref = $xml->get_file($file);
    say $xml_hash_ref->{root}->{config}->{database}->{user};

Load xml file content and return it as a hash or hash ref, not added to the object.

=cut

sub get_file {
    my ($self, $file) = @_;
    ($file && -f $file) || $self->app->abort("Error reading file '$file'. $!");
    my $xml = $self->xml->parsefile($file);
    return wantarray? %{$xml} : $xml;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 add_file()
    
    # load and append another xml file to the object
    $xml->add_file($another_file);

Load and append another xml file to the object.

=cut

sub add_file {
    my ($self, $file) = @_;
    my $xml = $self->get_file($file);
    while (my ($k, $v) = each %{$xml}) {
        $self->{vars}->{$k} = $v;
    }
    $self;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub DESTROY {
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=pod

=head1 Bugs

This project is available on github at L<https://github.com/mewsoft/Nile>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Nile>.

=head1 SOURCE

Source repository is at L<https://github.com/mewsoft/Nile>.

=head1 SEE ALSO

See L<Nile> for details about the complete framework.

=head1 AUTHOR

Ahmed Amin Elsheshtawy,  احمد امين الششتاوى <mewsoft@cpan.org>
Website: http://www.mewsoft.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2015 by Dr. Ahmed Amin Elsheshtawy احمد امين الششتاوى mewsoft@cpan.org, support@mewsoft.com,
L<https://github.com/mewsoft/Nile>, L<http://www.mewsoft.com>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
