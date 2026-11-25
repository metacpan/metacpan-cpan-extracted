# Triage Labels

The skills speak in five canonical triage roles. In this repo they are mapped to
**karr tags** with their default names.

| Role in mattpocock/skills  | karr tag          | Meaning                                    |
| -------------------------- | ----------------- | ------------------------------------------ |
| `needs-triage`             | `needs-triage`    | Maintainer has to assess the issue         |
| `needs-info`               | `needs-info`      | Waiting for feedback from the reporter     |
| `ready-for-agent`          | `ready-for-agent` | Fully specified, ready for an AFK agent    |
| `ready-for-human`          | `ready-for-human` | Needs a human implementation               |
| `wontfix`                  | `wontfix`         | Will not be worked on                      |

Apply / remove:

```bash
karr edit <id> --add_tag ready-for-agent
karr edit <id> --remove_tag needs-triage
karr list --tag ready-for-agent          # filter by role
```

When a skill names a role (e.g. "apply the AFK-ready triage label"), use the
matching tag string from this table. Usually a ticket carries exactly one
role tag at a time — when passing it on, remove the old one and set the
new one.