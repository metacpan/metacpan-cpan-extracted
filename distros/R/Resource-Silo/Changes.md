# Revision history for Resource::Silo

- 0.03    Tue Aug 15 2023
    - [api] Add 'class' to make Spring-style DI initilizers
      (like in Bread::Board)
    - [api] Add silo->ctl->meta to access container metadata

- 0.02    Sun Aug 13 2023
    - Improve documentation
    - Fix compatibility with older perls (5.010 & 5.012)

- 0.01    Sat Aug 12 2023
    - First version released on an unsuspecting world
    - `resource` DSL function for Moose-like resource declaration
    - re-exportable `silo` function to access the default container
    - `-class` parameter to use current package as the container class

