# About

## Variables

Types of varialbles are listed below.

| Type         | Description                                                                          |
|--------------|--------------------------------------------------------------------------------------|
| Bool         | Boolean represetend by either 0 or 1.                                                |
| Int          | Integer value of 0 or greater.                                                       |
| String       | A regular string, please don't use " or ' for anything other than quoting the value. |
| String Array | A comma seperated list of strings. Example: "network,windows,offprem"                |

The following variables are definable. Anything not undef is defined
in `starting_include.sh`.

| Variable                        | Type         | Default            | Description                                                                                                                   |
|---------------------------------|--------------|--------------------|-------------------------------------------------------------------------------------------------------------------------------|
| CLEAN_TO                        | Int          | 88                 | Percentage to use with file_cleaner_by_du                                                                                     |
| NO_MEER_CS                      | Bool         | 0                  | If enabled, no Meer client stats stuff is done.                                                                               |
| SAGAN_INSTANCES                 | String Array | ""                 | Sagan instance running on the system.                                                                                         |
| SURICATA_INSTANCES              | String Array | ""                 | Suricata instance running on the system.                                                                                      |

The following variable are built using the configured data. They are
handled by `ending_include.sh`.

| Variable            | Type         | Description                                                                                                       |
|---------------------|--------------|-------------------------------------------------------------------------------------------------------------------|
| CLIENT_STATS_ENABLE | Bool         | If there client stats should be being gathered or not. Generally going to be true of Sagan is going to be in use. |
| MEER_COUNT          | Int          | Number of expected Meer instances.                                                                                |
| SAGAN_OR_SURICATA   | Bool         | If Sagan or Suricata are in use.                                                                                  |
| SAGAN_COUNT         | Int          | Number of expected Sagan instances.                                                                               |
| SURICATA_COUNT      | Int          | Number of expected Suricata instances.                                                                            |
| ALL_SURICATA_RULES  | String Array | A list of all enabled rule files.                                                                                 |
| SYSTEM_NAME         | String       | The name of the system in Ansible or the like.                                                                    |
