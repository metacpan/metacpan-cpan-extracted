package MyApp::Controller::Books;

use strict;
use warnings;
use base 'Catalyst::Controller';
use FormElementContainer;


=head1 NAME

MyApp::Controller::Books - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index 

=cut

sub index : Private {
    my ( $self, $c ) = @_;

    $c->response->body('Matched MyApp::Controller::Books in Books.');
}


=head2 list

Fetch all book objects and pass to books/list.tt2 in stash to be displayed

=cut
 
sub list : Local {
    # Retrieve the usual perl OO '$self' for this object. $c is the Catalyst
    # 'Context' that's used to 'glue together' the various components
    # that make up the application
    my ($self, $c) = @_;

    # Retrieve all of the book records as book model objects and store in the
    # stash where they can be accessed by the TT template
    $c->stash->{books} = [$c->model('MyAppDB::Book')->all];
    
    # Set the TT template to use.  You will almost always want to do this
    # in your action methods (actions methods respond to user input in
    # your controllers).
    $c->stash->{template} = 'books/list.tt2';
}



=head2 url_create

Create a book with the supplied title and rating,
with manual authorization

=cut

sub url_create : Local {
    # In addition to self & context, get the title, rating & author_id args
    # from the URL.  Note that Catalyst automatically puts extra information
    # after the "/<controller_name>/<action_name/" into @_
    my ($self, $c, $title, $rating, $author_id) = @_;

    # Check the user's roles
    if ($c->check_user_roles('admin')) {
        # Call create() on the book model object. Pass the table 
        # columns/field values we want to set as hash values
        my $book = $c->model('MyAppDB::Book')->create({
                title   => $title,
                rating  => $rating
            });
        
        # Add a record to the join table for this book, mapping to 
        # appropriate author
        $book->add_to_book_authors({author_id => $author_id});
        # Note: Above is a shortcut for this:
        # $book->create_related('book_authors', {author_id => $author_id});
        
        # Assign the Book object to the stash for display in the view
        $c->stash->{book} = $book;
    
        # This is a hack to disable XSUB processing in Data::Dumper
        # (it's used in the view).  This is a work-around for a bug in
        # the interaction of some versions or Perl, Data::Dumper & DBIC.
        # You won't need this if you aren't using Data::Dumper (or if
        # you are running DBIC 0.06001 or greater), but adding it doesn't 
        # hurt anything either.
        $Data::Dumper::Useperl = 1;
    
        # Set the TT template to use
        $c->stash->{template} = 'books/create_done.tt2';
    } else {
        # Provide very simple feedback to the user
        $c->response->body('Unauthorized!');
    }
}



=head2 form_create

Display form to collect information for book to create

=cut

sub form_create : Local {
    my ($self, $c) = @_;

    # Set the TT template to use
    $c->stash->{template} = 'books/form_create.tt2';
}


=head2 form_create_do

Take information from form and add to database

=cut

sub form_create_do : Local {
    my ($self, $c) = @_;

    # Retrieve the values from the form
    my $title     = $c->request->params->{title}     || 'N/A';
    my $rating    = $c->request->params->{rating}    || 'N/A';
    my $author_id = $c->request->params->{author_id} || '1';

    # Create the book
    my $book = $c->model('MyAppDB::Book')->create({
            title   => $title,
            rating  => $rating,
        });
    # Handle relationship with author
    $book->add_to_book_authors({author_id => $author_id});

    # Store new model object in stash
    $c->stash->{book} = $book;

    # Avoid Data::Dumper issue mentioned earlier
    # You can probably omit this    
    $Data::Dumper::Useperl = 1;

    # Set the TT template to use
    $c->stash->{template} = 'books/create_done.tt2';
}



=head2 delete 

Delete a book
    
=cut

sub delete : Local {
    # $id = primary key of book to delete
    my ($self, $c, $id) = @_;

    # Search for the book and then delete it
    $c->model('MyAppDB::Book')->search({id => $id})->delete_all;

    # Use 'flash' to save information across requests util it's read
    $c->flash->{status_msg} = "Book deleted";
        
    # Redirect the user back to the list page with status msg as an arg
    $c->response->redirect($c->uri_for('/books/list'));
}



=head2 access_denied

Handle Catalyst::Plugin::Authorization::ACL access denied exceptions

=cut

sub access_denied : Private {
    my ($self, $c) = @_;

    # Set the error message
    $c->stash->{error_msg} = 'Unauthorized!';

    # Display the list
    $c->forward('list');
}


=head2 make_book_widget

Build an HTML::Widget form for book creation and updates

=cut


sub make_book_widget {
    my ($self, $c) = @_;

    # Create an HTML::Widget to build the form
    my $w = $c->widget('book_form')->method('post');

    # ***New: Use custom class to render each element in the form    
    $w->element_container_class('FormElementContainer');
    
    # Get authors
    my @authorObjs = $c->model("MyAppDB::Author")->all();
    my @authors = map {$_->id => $_->last_name }
                       sort {$a->last_name cmp $b->last_name} @authorObjs;

    # Create the form feilds
    $w->element('Textfield', 'title'  )->label('Title')->size(60);
    $w->element('Textfield', 'rating' )->label('Rating')->size(1);
    # Convert to multi-select list
    $w->element('Select',    'authors')->label('Authors')
        ->options(@authors)->multiple(1)->size(3);
    $w->element('Submit',    'submit' )->value('submit');

    # Set constraints
    $w->constraint(All     => qw/title rating authors/)
        ->message('Required. ');
    $w->constraint(Integer => qw/rating/)
        ->message('Must be an integer. ');
    $w->constraint(Range   => qw/rating/)->min(1)->max(5)
        ->message('Must be a number between 1 and 5. ');
    $w->constraint(Length  => qw/title/)->min(5)->max(50)
        ->message('Must be between 5 and 50 characters. ');

    # Set filters
    for my $column (qw/title rating authors/) {
        $w->filter( HTMLEscape => $column );
        $w->filter( TrimEdges  => $column );
    }

    # Return the widget    
    return $w;
}


=head2 hw_create

Build an HTML::Widget form for book creation and updates

=cut

sub hw_create : Local {
    my ($self, $c) = @_;

    # Create the widget and set the action for the form
    my $w = $self->make_book_widget($c);
    $w->action($c->uri_for('hw_create_do'));

    # Write form to stash variable for use in template
    $c->stash->{widget_result} = $w->result;

    # Set the template
    $c->stash->{template} = 'books/hw_form.tt2';
}


=head2 hw_create_do

Build an HTML::Widget form for book creation and updates

=cut

=head2 hw_create_do

Build an HTML::Widget form for book creation and updates

=cut

sub hw_create_do : Local {
    my ($self, $c) = @_;

    # Create the widget and set the action for the form
    my $w = $self->make_book_widget($c);
    $w->action($c->uri_for('hw_create_do'));

    # Validate the form parameters
    my $result = $w->process($c->req);

    # Write form (including validation error messages) to
    # stash variable for use in template
    $c->stash->{widget_result} = $result;

    # Were their validation errors?
    if ($result->has_errors) {
        # Warn the user at the top of the form that there were errors.
        # Note that there will also be per-field feedback on
        # validation errors because of '$w->process($c->req)' above.
        $c->stash->{error_msg} = 'Validation errors!';
    } else {
        my $book = $c->model('MyAppDB::Book')->new({});
        $book->populate_from_widget($result);

        # Add a record to the join table for this book, mapping to
        # appropriate author.  Note that $authors will be 1 author as
        # a scalar or ref to list of authors depending on how many the
        # user selected; the 'ref $authors ?...' handles both cases
        my $authors = $c->request->params->{authors};
        foreach my $author (ref $authors ? @$authors : $authors) {
            $book->add_to_book_authors({author_id => $author});
        }

        # Set a status message for the user
        $c->stash->{status_msg} = 'Book created';
        
        # Redisplay an empty form for another
        $c->stash->{widget_result} = $w->result;
    }

    # Set the template
    $c->stash->{template} = 'books/hw_form.tt2';
}


=head1 AUTHOR

root

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
