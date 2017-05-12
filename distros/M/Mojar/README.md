# Mojar

A small booster pack for Mojolicious focused on integration.
The (soft) criteria are
*   Filesystem footprint kept small.
*   Number of package dependencies kept low.
*   XS files avoided where practical.
*   Non-linux platforms (incl Strawberry Perl) supported where practical.

## Features

*   Mojar::Cache

    A bare-bones cache.  Aims to be sufficient for everyday use while providing
an easy upgrade path to CHI when better performance or richer functionality is
required.

*   Mojar::Util

    A small set of utility functions.

*   Mojar::Config::Ini

    A lightweight reader of ini-style configuration files.

## See also

The real content is split out into separate distributions.

*   Mojar::Mysql

    A set of interfaces for working with MySQL databases, of most use to those
    working with more than one server.

*   Mojar::Oracle

    A db connector for Oracle databases.  [Much less mature than its Mysql
    sibling.]

*   Mojar::Google::Analytics

    Interface for easy (unattended) downloading of reporting data.

*   Mojar::Cron

    Interface for cron calculations.

*   Mojar::BulkSms

    Interface to popular SMS sending service.
