# Revision history for Resource::Silo

- 0.11    Wed Oct 04 2023
    - Use namespace::clean to remove unneeded imports from the container class
    - Use Moo internally, enforce Moo/Moose compatibility

- 0.10    Fri Sep 01 2023
    - [api] Add meta->show(name) method to inspect resource definitions
    - [bug] default cleanup_order for literals = inf
    - [bug] Improve error messages about bad dependencies, add implicit deps as a special case

- 0.09    Mon Aug 28 2023
    - [api][break] Only allow dependencies on previously declared resources
    - [api] Add `loose_deps` flag to allow forward and/or dangling dependencies

- 0.08    Mon Aug 21 2023
    - [api] Add 'literal' resources that just point to a value
    - [api][break] rename flag: derivative => derived

- 0.07    Sun Aug 20 2023
    - [api] Returning `undef` from initializer is now considered an error
    - [bug] Fix throwing on module load failure in lower perl versions
    - [bug] self_check caused empty dependencies list to appear due to autovivification

- 0.06    Sat Aug 19 2023
    - [api] Add silo->ctl->meta->self_check to test that the setup is correct (deps+modules so far)
    - [api] Add 'require' option to preload modules like 'class' does

- 0.05    Sat Aug 19 2023
    - [test] Make sure tests work on windows (quotemeta \)
    - [doc] Add more examples to doc

- 0.04    Thu Aug 17 2023
    - Make constructor more compatible with Moo

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

