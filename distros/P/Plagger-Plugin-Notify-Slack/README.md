# NAME

Plagger::Plugin::Notify::Slack - Notify feed updates to Slack

# SYNOPSIS

    - module: Notify::Slack
      config:
        webhook_url: {incoming_webhook_url}

# CONFIG

- webhook\_url

    Inconming webhooks URL. (required)

- username

    Username for your bot.

- icon\_url

    Icon URL for your bot.

- icon\_emoji

    Icon emoji for your bot.

- channel

    Channnel for notifying.

# DESCRIPTION

Plagger::Plugin::Notify::Slack allows you to notify feed updates to Slack channels using Inconming Webhooks.

# LICENSE

Copyright (C) zoncoen.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

zoncoen <zoncoen@gmail.com>
