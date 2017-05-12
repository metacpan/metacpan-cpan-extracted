# NAME

Plack::Middleware::PostErrorToSlack - Post error message to Slack when you app dies

# SYNOPSIS

    enable "PostErrorToSlack",
        webhook_url => 'https://hooks.slack.com/services/...'; # Incoming Webhook URL

# DESCRIPTION

When your app dies, Plack::Middleware::PostErrorToSlack posts the error to Slack, and rethrow the error.

You can share your error with your team members, And you can discuss how to fix it.

This module is mainly for local development. Do not enable this on production environment.

# CONFIGURATION

- webhook\_url (required)

    You must set up an Incoming Webhooks and set webhook\_url. Read the document below.

    [https://api.slack.com/incoming-webhooks](https://api.slack.com/incoming-webhooks)

- channel, username, icon\_url, icon\_emoji

    You can override these parameters.

# LICENSE

Copyright (C) hitode909.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

hitode909 <hitode909@gmail.com>
