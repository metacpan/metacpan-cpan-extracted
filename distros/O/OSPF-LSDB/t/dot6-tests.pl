{
id => "network.0",
text => "Multiple networks, no error.",
errors => [],
colors => { black => 1, },
clusters => {},
options => "-bse",
yaml => <<EOF,
---
database:
  networks:
    - address: 0.0.1.1
      area: 1.0.0.0
      attachments:
        - routerid: 0.1.0.0
        - routerid: 0.2.0.0
      routerid: 0.1.0.0
    - address: 0.0.1.129
      area: 1.0.0.0
      attachments:
        - routerid: 0.1.0.0
        - routerid: 0.2.0.0
      routerid: 0.1.0.0
    - address: 0.0.2.1
      area: 2.0.0.0
      attachments:
        - routerid: 0.1.0.0
        - routerid: 0.3.0.0
      routerid: 0.1.0.0
  routers:
    - area: 1.0.0.0
      bits:
        B: 1
        E: 1
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.1.1
          metric: 10
          routerid: 0.1.0.0
          type: transit
        - address: 0.0.1.129
          interface: 0.0.1.129
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.1.0.0
    - area: 1.0.0.0
      bits:
        B: 0
        E: 1
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.1.2
          metric: 10
          routerid: 0.1.0.0
          type: transit
        - address: 0.0.1.129
          interface: 0.0.1.130
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.2.0.0
    - area: 2.0.0.0
      bits:
        B: 1
        E: 1
        V: 0
      links:
        - address: 0.0.2.1
          interface: 0.0.2.1
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.1.0.0
    - area: 2.0.0.0
      bits:
        B: 1
        E: 1
        V: 0
      links:
        - address: 0.0.2.1
          interface: 0.0.3.3
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.3.0.0
self:
  areas:
    - 1.0.0.0
    - 2.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "network.2",
text => "Network in multiple areas.",
errors => [
"Network 0.0.1.1\@0.1.0.0 at router 0.1.0.0 in area 2.0.0.0 is designated but transit link is not.",
"Network 0.0.1.1\@0.1.0.0 at router 0.1.0.0 in multiple areas.",
"Network 0.0.1.1\@0.1.0.0 not unique at router 0.1.0.0.",
],
colors => { black => 2, orange => 2, tan => 1, },
clusters => {},
options => "-bse",
yaml => <<EOF,
---
database:
  networks:
    - address: 0.0.1.1
      area: 1.0.0.0
      attachments:
        - routerid: 0.1.0.0
        - routerid: 0.2.0.0
      routerid: 0.1.0.0
    - address: 0.0.1.1
      area: 2.0.0.0
      attachments:
        - routerid: 0.1.0.0
        - routerid: 0.2.0.0
      routerid: 0.1.0.0
  routers:
    - area: 1.0.0.0
      bits:
        B: 1
        E: 1
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.1.1
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.1.0.0
    - area: 1.0.0.0
      bits:
        B: 1
        E: 1
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.1.2
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.2.0.0
    - area: 2.0.0.0
      bits:
        B: 1
        E: 1
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.1.129
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.1.0.0
    - area: 2.0.0.0
      bits:
        B: 1
        E: 1
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.1.130
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.2.0.0
self:
  areas:
    - 1.0.0.0
    - 2.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "network.3",
text => "Network duplicate in area.",
errors => [
"Network 0.0.1.1\@0.1.0.0 at router 0.1.0.0 has multiple entries in area 1.0.0.0.",
"Network 0.0.1.1\@0.1.0.0 not unique at router 0.1.0.0.",
],
colors => { yellow => 1, },
clusters => {},
options => "-bse",
yaml => <<EOF,
---
database:
  networks:
    - address: 0.0.1.1
      area: 1.0.0.0
      attachments:
        - routerid: 0.1.0.0
        - routerid: 0.2.0.0
      routerid: 0.1.0.0
    - address: 0.0.1.1
      area: 1.0.0.0
      attachments:
        - routerid: 0.1.0.0
        - routerid: 0.2.0.0
      routerid: 0.1.0.0
  routers:
    - area: 1.0.0.0
      bits:
        B: 0
        E: 1
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.1.1
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.1.0.0
    - area: 1.0.0.0
      bits:
        B: 0
        E: 1
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.1.2
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.2.0.0
self:
  areas:
    - 1.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "network.7",
text => "Network without attached router.",
errors => [
"Network 0.0.1.1\@0.1.0.0 at router 0.1.0.0 not attached to any router in area 1.0.0.0.",
"Network 0.0.1.1\@0.1.0.0 not attached to designated router 0.1.0.0 in area 1.0.0.0.",
],
colors => { red => 2, },
clusters => {},
options => "-bse",
yaml => <<EOF,
---
database:
  networks:
    - address: 0.0.1.1
      area: 1.0.0.0
      attachments:
      routerid: 0.1.0.0
  routers:
    - area: 1.0.0.0
      bits:
        B: 0
        E: 1
        V: 0
      links:
      routerid: 0.1.0.0
self:
  areas:
    - 1.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "network.8",
text => "Network with only one attached router.",
errors => [
"Network 0.0.1.1\@0.1.0.0 at router 0.1.0.0 attached only to router 0.1.0.0 in area 1.0.0.0.",
],
colors => { brown => 1, },
clusters => {},
options => "-bse",
yaml => <<EOF,
---
database:
  networks:
    - address: 0.0.1.1
      area: 1.0.0.0
      attachments:
        - routerid: 0.1.0.0
      routerid: 0.1.0.0
  routers:
    - area: 1.0.0.0
      bits:
        B: 0
        E: 1
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.1.1
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.1.0.0
self:
  areas:
    - 1.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "network.9",
text => "Network with wrong designated router.",
errors => [
"Network 0.0.1.1\@0.1.0.0 at router 0.1.0.0 in area 1.0.0.0 is designated but transit link is not.",
],
colors => { tan => 1, },
clusters => {},
options => "-bse",
yaml => <<EOF,
---
database:
  networks:
    - address: 0.0.1.1
      area: 1.0.0.0
      attachments:
        - routerid: 0.1.0.0
        - routerid: 0.2.0.0
      routerid: 0.1.0.0
  routers:
    - area: 1.0.0.0
      bits:
        B: 0
        E: 0
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.1.3
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.1.0.0
    - area: 1.0.0.0
      bits:
        B: 0
        E: 0
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.1.2
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.2.0.0
self:
  areas:
    - 1.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "netedge.0",
text => "Network in multiple nets.",
errors => [],
colors => { black => 1, },
clusters => {},
options => "-bse",
yaml => <<EOF,
---
database:
  networks:
    - address: 0.0.1.1
      area: 1.0.0.0
      attachments:
        - routerid: 0.1.0.0
        - routerid: 0.3.0.0
      routerid: 0.1.0.0
    - address: 0.0.2.2
      area: 2.0.0.0
      attachments:
        - routerid: 0.2.0.0
        - routerid: 0.3.0.0
      routerid: 0.2.0.0
  routers:
    - area: 1.0.0.0
      bits:
        B: 0
        E: 1
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.1.1
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.1.0.0
    - area: 2.0.0.0
      bits:
        B: 0
        E: 1
        V: 0
      links:
        - address: 0.0.2.2
          interface: 0.0.2.2
          metric: 10
          routerid: 0.2.0.0
          type: transit
      routerid: 0.2.0.0
    - area: 1.0.0.0
      bits:
        B: 1
        E: 1
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.1.3
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.3.0.0
    - area: 2.0.0.0
      bits:
        B: 1
        E: 1
        V: 0
      links:
        - address: 0.0.2.2
          interface: 0.0.2.3
          metric: 10
          routerid: 0.2.0.0
          type: transit
      routerid: 0.3.0.0
self:
  areas:
    - 1.0.0.0
    - 2.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "netedge.1",
text => "Network attached to one router twice.",
errors => [
"Network 0.0.1.1\@0.1.0.0 in area 1.0.0.0 at router 0.1.0.0 attached to router 0.1.0.0 multiple times.",
],
colors => { yellow => 2, },
clusters => {},
options => "-bse",
yaml => <<EOF,
---
database:
  networks:
    - address: 0.0.1.1
      area: 1.0.0.0
      attachments:
        - routerid: 0.1.0.0
        - routerid: 0.1.0.0
        - routerid: 0.2.0.0
      routerid: 0.1.0.0
  routers:
    - area: 1.0.0.0
      bits:
        B: 0
        E: 1
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.1.1
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.1.0.0
    - area: 1.0.0.0
      bits:
        B: 0
        E: 1
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.1.2
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.2.0.0
self:
  areas:
    - 1.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "netedge.2",
text => "Duplicate network attached to one router.",
errors => [
"Network 0.0.1.1\@0.1.0.0 at router 0.1.0.0 has multiple entries in area 1.0.0.0.",
"Network 0.0.1.1\@0.1.0.0 in area 1.0.0.0 at router 0.1.0.0 attached to router 0.1.0.0 multiple times.",
"Network 0.0.1.1\@0.1.0.0 not unique at router 0.1.0.0.",
],
colors => { yellow => 3, },
clusters => {},
options => "-bse",
yaml => <<EOF,
---
database:
  networks:
    - address: 0.0.1.1
      area: 1.0.0.0
      attachments:
        - routerid: 0.1.0.0
        - routerid: 0.1.0.0
      routerid: 0.1.0.0
    - address: 0.0.1.1
      area: 1.0.0.0
      attachments:
        - routerid: 0.1.0.0
        - routerid: 0.2.0.0
      routerid: 0.1.0.0
  routers:
    - area: 1.0.0.0
      bits:
        B: 0
        E: 1
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.1.1
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.1.0.0
    - area: 1.0.0.0
      bits:
        B: 0
        E: 1
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.1.2
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.2.0.0
self:
  areas:
    - 1.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "netedge.3",
text => "Router in wrong area for network attachment.",
errors => [
"Network 0.0.1.1\@0.1.0.0 and router 0.2.0.0 not in same area 1.0.0.0.",
],
colors => { orange => 1, },
clusters => {},
options => "-bse",
yaml => <<EOF,
---
database:
  networks:
    - address: 0.0.1.1
      area: 1.0.0.0
      attachments:
        - routerid: 0.1.0.0
        - routerid: 0.2.0.0
      routerid: 0.1.0.0
  routers:
    - area: 1.0.0.0
      bits:
        B: 0
        E: 1
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.1.1
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.1.0.0
    - area: 2.0.0.0
      bits:
        B: 0
        E: 1
        V: 0
      links:
      routerid: 0.2.0.0
self:
  areas:
    - 1.0.0.0
    - 2.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "netedge.4",
text => "Designated router in wrong area for network.",
errors => [
"Network 0.0.1.1\@0.1.0.0 and router 0.1.0.0 not in same area 2.0.0.0.",
],
colors => { orange => 1, },
clusters => {},
options => "-bse",
yaml => <<EOF,
---
database:
  networks:
    - address: 0.0.1.1
      area: 2.0.0.0
      attachments:
        - routerid: 0.1.0.0
        - routerid: 0.2.0.0
      routerid: 0.1.0.0
  routers:
    - area: 1.0.0.0
      bits:
        B: 1
        E: 1
        V: 0
      links:
      routerid: 0.1.0.0
    - area: 2.0.0.0
      bits:
        B: 1
        E: 1
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.1.2
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.2.0.0
self:
  areas:
    - 1.0.0.0
    - 2.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "netedge.5",
text => "Network designated router not attached.",
errors => [
"Network 0.0.1.1\@0.1.0.0 not attached to designated router 0.1.0.0 in area 1.0.0.0.",
"Transit link at router 0.1.0.0 not attached by network 0.0.1.1\@0.1.0.0 in area 1.0.0.0.",
],
colors => { brown => 1, red => 1, },
clusters => {},
options => "-bse",
yaml => <<EOF,
---
database:
  networks:
    - address: 0.0.1.1
      area: 1.0.0.0
      attachments:
        - routerid: 0.2.0.0
        - routerid: 0.3.0.0
      routerid: 0.1.0.0
  routers:
    - area: 1.0.0.0
      bits:
        B: 0
        E: 1
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.1.1
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.1.0.0
    - area: 1.0.0.0
      bits:
        B: 0
        E: 1
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.1.2
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.2.0.0
    - area: 1.0.0.0
      bits:
        B: 0
        E: 1
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.1.3
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.3.0.0
self:
  areas:
    - 1.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "netedge.6",
text => "Network to router not symmetric.",
errors => [
"Network 0.0.1.1\@0.1.0.0 not transit net of attached router 0.2.0.0 in area 1.0.0.0.",
],
colors => { brown => 1, },
clusters => {},
options => "-bse",
yaml => <<EOF,
---
database:
  networks:
    - address: 0.0.1.1
      area: 1.0.0.0
      attachments:
        - routerid: 0.1.0.0
        - routerid: 0.2.0.0
      routerid: 0.1.0.0
  routers:
    - area: 1.0.0.0
      bits:
        B: 0
        E: 1
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.1.1
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.1.0.0
    - area: 1.0.0.0
      bits:
        B: 0
        E: 1
        V: 0
      links:
      routerid: 0.2.0.0
self:
  areas:
    - 1.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "transit.0",
text => "Multiple transit nets, no error.",
errors => [],
colors => { black => 1, },
clusters => {},
options => "-bse",
yaml => <<EOF,
---
database:
  networks:
    - address: 0.0.1.1
      area: 1.0.0.0
      attachments:
        - routerid: 0.1.0.0
        - routerid: 0.3.0.0
      routerid: 0.1.0.0
    - address: 0.0.2.1
      area: 2.0.0.0
      attachments:
        - routerid: 0.1.0.0
        - routerid: 0.2.0.0
      routerid: 0.1.0.0
    - address: 0.0.3.1
      area: 2.0.0.0
      attachments:
        - routerid: 0.1.0.0
        - routerid: 0.2.0.0
      routerid: 0.1.0.0
  routers:
    - area: 1.0.0.0
      bits:
        B: 1
        E: 1
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.1.1
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.1.0.0
    - area: 1.0.0.0
      bits:
        B: 0
        E: 1
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.1.3
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.3.0.0
    - area: 2.0.0.0
      bits:
        B: 1
        E: 1
        V: 0
      links:
        - address: 0.0.2.1
          interface: 0.0.2.1
          metric: 10
          routerid: 0.1.0.0
          type: transit
        - address: 0.0.3.1
          interface: 0.0.3.1
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.1.0.0
    - area: 2.0.0.0
      bits:
        B: 0
        E: 1
        V: 0
      links:
        - address: 0.0.2.1
          interface: 0.0.2.2
          metric: 10
          routerid: 0.1.0.0
          type: transit
        - address: 0.0.3.1
          interface: 0.0.3.2
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.2.0.0
self:
  areas:
    - 1.0.0.0
    - 2.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "transit.1",
text => "Transit network missing.",
errors => [
"Transit network 0.0.1.1\@0.1.0.0 network missing.",
],
colors => { red => 1, },
clusters => {},
options => "-bse",
yaml => <<EOF,
---
database:
  networks:
    - address: 0.0.2.1
      area: 1.0.0.0
      attachments:
        - routerid: 0.1.0.0
        - routerid: 0.2.0.0
      routerid: 0.1.0.0
  routers:
    - area: 1.0.0.0
      bits:
        B: 1
        E: 1
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.1.1
          metric: 10
          routerid: 0.1.0.0
          type: transit
        - address: 0.0.2.1
          interface: 0.0.2.1
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.1.0.0
    - area: 1.0.0.0
      bits:
        B: 1
        E: 1
        V: 0
      links:
        - address: 0.0.2.1
          interface: 0.0.2.2
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.2.0.0
self:
  areas:
    - 1.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "transit.2",
text => "Transit network missing in area.",
errors => [
"Network 0.0.1.1\@0.1.0.0 at router 0.1.0.0 in area 2.0.0.0 is designated but transit link is not.",
"Transit network 0.0.1.1\@0.1.0.0 in area 1.0.0.0 at router 0.1.0.0 and network not in same area.",
],
colors => { black => 1, yellow => 1, tan => 1, },
clusters => {},
options => "-bse",
yaml => <<EOF,
---
database:
  networks:
    - address: 0.0.1.1
      area: 2.0.0.0
      attachments:
        - routerid: 0.1.0.0
        - routerid: 0.2.0.0
      routerid: 0.1.0.0
  routers:
    - area: 1.0.0.0
      bits:
        B: 1
        E: 1
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.1.1
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.1.0.0
    - area: 2.0.0.0
      bits:
        B: 1
        E: 1
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.1.129
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.1.0.0
    - area: 2.0.0.0
      bits:
        B: 0
        E: 1
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.1.130
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.2.0.0
self:
  areas:
    - 1.0.0.0
    - 2.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "transit.3",
text => "Transit network missing at multiple routers.",
errors => [
"Transit network 0.0.1.1\@0.1.0.0 missing in area 1.0.0.0 at multiple routers.",
],
colors => { blue => 2, },
clusters => {},
options => "-bse",
yaml => <<EOF,
---
database:
  routers:
    - area: 1.0.0.0
      bits:
        B: 1
        E: 1
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.1.1
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.1.0.0
    - area: 1.0.0.0
      bits:
        B: 1
        E: 1
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.1.2
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.2.0.0
self:
  areas:
    - 1.0.0.0
    - 2.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "transit.4",
text => "Transit network missing at router in multiple areas.",
errors => [
"Transit network 0.0.1.1\@0.1.0.0 missing in multiple areas.",
],
colors => { orange => 2, },
clusters => {},
options => "-bse",
yaml => <<EOF,
---
database:
  routers:
    - area: 1.0.0.0
      bits:
        B: 1
        E: 1
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.1.1
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.1.0.0
    - area: 2.0.0.0
      bits:
        B: 1
        E: 1
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.1.2
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.2.0.0
self:
  areas:
    - 1.0.0.0
    - 2.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "transit.5",
text => "Transit network missing in multiple areas.",
errors => [
"Transit network 0.0.1.1\@0.1.0.0 missing in multiple areas.",
],
colors => { black => 1, orange => 2, },
clusters => {},
options => "-bse",
yaml => <<EOF,
---
database:
  routers:
    - area: 1.0.0.0
      bits:
        B: 1
        E: 1
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.1.1
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.1.0.0
    - area: 2.0.0.0
      bits:
        B: 1
        E: 1
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.1.2
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.1.0.0
self:
  areas:
    - 1.0.0.0
    - 2.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "transit.6",
text => "Transit network missing in area at router mult entries.",
errors => [
"Transit network 0.0.1.1\@0.1.0.0 at router 0.1.0.0 has multiple entries in area 1.0.0.0.",
"Transit network 0.0.1.1\@0.1.0.0 network missing.",
],
colors => { red => 1, yellow => 2, },
clusters => {},
options => "-bse",
yaml => <<EOF,
---
database:
  routers:
    - area: 1.0.0.0
      bits:
        B: 1
        E: 1
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.1.1
          metric: 10
          routerid: 0.1.0.0
          type: transit
        - address: 0.0.1.1
          interface: 0.0.1.2
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.1.0.0
self:
  areas:
    - 1.0.0.0
    - 2.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "transedge.0",
text => "Multiple transit nets with edges, no error.",
errors => [],
colors => { black => 1, },
clusters => {},
options => "-bse",
yaml => <<EOF,
---
database:
  networks:
    - address: 0.0.1.1
      area: 1.0.0.0
      attachments:
        - routerid: 0.1.0.0
        - routerid: 0.3.0.0
      routerid: 0.1.0.0
    - address: 0.0.2.1
      area: 2.0.0.0
      attachments:
        - routerid: 0.1.0.0
        - routerid: 0.2.0.0
      routerid: 0.1.0.0
    - address: 0.0.3.1
      area: 2.0.0.0
      attachments:
        - routerid: 0.1.0.0
        - routerid: 0.2.0.0
      routerid: 0.1.0.0
  routers:
    - area: 1.0.0.0
      bits:
        B: 1
        E: 1
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.1.1
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.1.0.0
    - area: 1.0.0.0
      bits:
        B: 0
        E: 1
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.1.3
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.3.0.0
    - area: 2.0.0.0
      bits:
        B: 1
        E: 1
        V: 0
      links:
        - address: 0.0.2.1
          interface: 0.0.2.1
          metric: 10
          routerid: 0.1.0.0
          type: transit
        - address: 0.0.3.1
          interface: 0.0.3.1
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.1.0.0
    - area: 2.0.0.0
      bits:
        B: 0
        E: 1
        V: 0
      links:
        - address: 0.0.2.1
          interface: 0.0.2.2
          metric: 10
          routerid: 0.1.0.0
          type: transit
        - address: 0.0.3.1
          interface: 0.0.3.2
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.2.0.0
self:
  areas:
    - 1.0.0.0
    - 2.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "transedge.1",
text => "Transit network edge duplicate.",
errors => [
"Transit network 0.0.1.1\@0.1.0.0 at router 0.1.0.0 has multiple entries in area 1.0.0.0.",
],
colors => { yellow => 2, },
clusters => {},
options => "-bse",
yaml => <<EOF,
---
database:
  networks:
    - address: 0.0.1.1
      area: 1.0.0.0
      attachments:
        - routerid: 0.1.0.0
        - routerid: 0.2.0.0
      routerid: 0.1.0.0
  routers:
    - area: 1.0.0.0
      bits:
        B: 0
        E: 1
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.1.1
          metric: 10
          routerid: 0.1.0.0
          type: transit
        - address: 0.0.1.1
          interface: 0.0.1.129
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.1.0.0
    - area: 1.0.0.0
      bits:
        B: 0
        E: 1
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.1.2
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.2.0.0
self:
  areas:
    - 1.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "transedge.3",
text => "Transit link to network not symmetric.",
errors => [
"Transit link at router 0.2.0.0 not attached by network 0.0.1.1\@0.1.0.0 in area 1.0.0.0.",
],
colors => { brown => 1, },
clusters => {},
options => "-bse",
yaml => <<EOF,
---
database:
  networks:
    - address: 0.0.1.1
      area: 1.0.0.0
      attachments:
        - routerid: 0.1.0.0
        - routerid: 0.3.0.0
      routerid: 0.1.0.0
  routers:
    - area: 1.0.0.0
      bits:
        B: 0
        E: 1
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.1.1
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.1.0.0
    - area: 1.0.0.0
      bits:
        B: 0
        E: 1
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.1.2
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.2.0.0
    - area: 1.0.0.0
      bits:
        B: 0
        E: 1
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.1.3
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.3.0.0
self:
  areas:
    - 1.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "transedge.4",
text => "Transit link reuses interface address at router.",
errors => [
"Network 0.0.1.128\@0.1.0.0 at router 0.1.0.0 in area 1.0.0.0 is designated but transit link is not.",
"Network 0.0.1.1\@0.1.0.0 at router 0.1.0.0 in area 1.0.0.0 is designated but transit link is not.",
"Transit link at router 0.1.0.0 to network 0.0.1.128\@0.1.0.0 interface address 0.0.1.129 not unique.",
"Transit link at router 0.1.0.0 to network 0.0.1.1\@0.1.0.0 interface address 0.0.1.129 not unique.",
],
colors => { green => 2, tan => 2, },
clusters => {},
options => "-bse",
yaml => <<EOF,
---
database:
  networks:
    - address: 0.0.1.1
      area: 1.0.0.0
      attachments:
        - routerid: 0.1.0.0
        - routerid: 0.2.0.0
      routerid: 0.1.0.0
    - address: 0.0.1.128
      area: 1.0.0.0
      attachments:
        - routerid: 0.1.0.0
        - routerid: 0.2.0.0
      routerid: 0.1.0.0
  routers:
    - area: 1.0.0.0
      bits:
        B: 0
        E: 1
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.1.129
          metric: 10
          routerid: 0.1.0.0
          type: transit
        - address: 0.0.1.128
          interface: 0.0.1.129
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.1.0.0
    - area: 1.0.0.0
      bits:
        B: 0
        E: 1
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.1.2
          metric: 10
          routerid: 0.1.0.0
          type: transit
        - address: 0.0.1.128
          interface: 0.0.1.130
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.2.0.0
self:
  areas:
    - 1.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "transedge.5",
text => "Transit link reuses interface address to network.",
errors => [],
colors => {},
clusters => {},
options => "-bse",
yaml => <<EOF,
---
database:
  networks:
    - address: 0.0.1.1
      area: 1.0.0.0
      attachments:
        - routerid: 0.1.0.0
        - routerid: 0.2.0.0
        - routerid: 0.3.0.0
      routerid: 0.1.0.0
  routers:
    - area: 1.0.0.0
      bits:
        B: 0
        E: 1
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.1.1
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.1.0.0
    - area: 1.0.0.0
      bits:
        B: 0
        E: 1
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.1.2
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.2.0.0
    - area: 1.0.0.0
      bits:
        B: 0
        E: 1
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.1.2
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.3.0.0
self:
  areas:
    - 1.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "router.0",
text => "Multiple routers, no error.",
errors => [],
colors => { black => 1, },
clusters => {},
options => "-bse",
yaml => <<EOF,
---
database:
  routers:
    - area: 1.0.0.0
      bits:
        B: 1
        E: 1
        V: 0
      links:
      routerid: 0.1.0.0
    - area: 2.0.0.0
      bits:
        B: 1
        E: 1
        V: 0
      links:
      routerid: 0.1.0.0
    - area: 1.0.0.0
      bits:
        B: 0
        E: 1
        V: 0
      links:
      routerid: 0.2.0.0
self:
  areas:
    - 1.0.0.0
    - 2.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "router.1",
text => "Router not border.",
errors => [
"Router 0.1.0.0 in multiple areas is not border router in areas 2.0.0.0.",
],
colors => { orange => 1, },
clusters => {},
options => "-bse",
yaml => <<EOF,
---
database:
  routers:
    - area: 1.0.0.0
      bits:
        B: 1
        E: 1
        V: 0
      links:
      routerid: 0.1.0.0
    - area: 2.0.0.0
      bits:
        B: 0
        E: 1
        V: 0
      links:
      routerid: 0.1.0.0
self:
  areas:
    - 1.0.0.0
    - 2.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "router.2",
text => "Router duplicate in area.",
errors => [
"Router 0.1.0.0 has multiple link state IDs 0.0.0.1 in area 1.0.0.0.",
],
colors => { black => 1, magenta => 1, },
clusters => {},
options => "-bse",
yaml => <<EOF,
---
database:
  routers:
    - area: 1.0.0.0
      bits:
        B: 0
        E: 1
        V: 0
      links:
      router: 0.0.0.1
      routerid: 0.1.0.0
    - area: 1.0.0.0
      bits:
        B: 0
        E: 1
        V: 0
      links:
      router: 0.0.0.1
      routerid: 0.1.0.0
    - area: 1.0.0.0
      bits:
        B: 1
        E: 1
        V: 0
      links:
      router: 0.0.0.1
      routerid: 0.2.0.0
    - area: 2.0.0.0
      bits:
        B: 1
        E: 1
        V: 0
      links:
      router: 0.0.0.1
      routerid: 0.2.0.0
self:
  areas:
    - 1.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "router.3",
text => "Missing router referenced from network.",
errors => [
"Network 0.0.1.1\@0.1.0.0 not attached to designated router 0.1.0.0 in area 1.0.0.0.",
"Router 0.1.0.0 missing.",
],
colors => { red => 2, },
clusters => {},
options => "-bse",
yaml => <<EOF,
---
database:
  networks:
    - address: 0.0.1.1
      area: 1.0.0.0
      attachments:
        - routerid: 0.2.0.0
        - routerid: 0.3.0.0
      routerid: 0.1.0.0
  routers:
    - area: 1.0.0.0
      bits:
        B: 0
        E: 1
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.1.2
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.2.0.0
    - area: 1.0.0.0
      bits:
        B: 0
        E: 1
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.1.3
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.3.0.0
self:
  areas:
    - 1.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "router.4",
text => "Missing router referenced from network and attachment.",
errors => [
"Router 0.1.0.0 missing.",
],
colors => { red => 1, },
clusters => {},
options => "-bse",
yaml => <<EOF,
---
database:
  networks:
    - address: 0.0.1.1
      area: 1.0.0.0
      attachments:
        - routerid: 0.1.0.0
        - routerid: 0.2.0.0
      routerid: 0.1.0.0
  routers:
    - area: 1.0.0.0
      bits:
        B: 0
        E: 1
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.1.2
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.2.0.0
self:
  areas:
    - 1.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "router.5",
text => "Missing router referenced from attachment.",
errors => [
"Router 0.2.0.0 missing.",
],
colors => { red => 1, },
clusters => {},
options => "-bse",
yaml => <<EOF,
---
database:
  networks:
    - address: 0.0.1.1
      area: 1.0.0.0
      attachments:
        - routerid: 0.1.0.0
        - routerid: 0.2.0.0
      routerid: 0.1.0.0
  routers:
    - area: 1.0.0.0
      bits:
        B: 0
        E: 1
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.1.1
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.1.0.0
self:
  areas:
    - 1.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "router.6",
text => "Missing router referenced from summary.",
errors => [
"Router 0.1.0.0 missing.",
],
colors => { red => 1, },
clusters => {},
options => "-bse",
yaml => <<EOF,
---
database:
  summarys:
    - address: 0.0.1.0
      area: 1.0.0.0
      metric: 10
      prefixaddress: 1::0
      prefixlength: 64
      routerid: 0.1.0.0
self:
  areas:
    - 1.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "router.7",
text => "Missing router referenced from boundary.",
errors => [
"Router 0.1.0.0 missing.",
],
colors => { red => 1, },
clusters => {},
options => "-bse",
yaml => <<EOF,
---
database:
  boundarys:
    - address: 0.0.1.0
      area: 1.0.0.0
      asbrouter: 0.2.0.0
      metric: 10
      routerid: 0.1.0.0
self:
  areas:
    - 1.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "router.8",
text => "Missing router referenced from external.",
errors => [
"Router 0.1.0.0 missing.",
],
colors => { red => 1, },
clusters => {},
options => "-bse",
yaml => <<EOF,
---
database:
  externals:
    - address: 0.0.1.0
      metric: 10
      prefixaddress: 1::0
      prefixlength: 64
      routerid: 0.1.0.0
      type: 1
self:
  areas:
    - 1.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "router.9",
text => "Missing router referenced from all.",
errors => [
"Router 0.1.0.0 missing.",
],
colors => { red => 1, },
clusters => {},
options => "-bse",
yaml => <<EOF,
---
database:
  networks:
    - address: 0.0.1.1
      area: 1.0.0.0
      attachments:
        - routerid: 0.1.0.0
        - routerid: 0.2.0.0
      routerid: 0.1.0.0
    - address: 0.0.2.2
      area: 1.0.0.0
      attachments:
        - routerid: 0.1.0.0
        - routerid: 0.2.0.0
      routerid: 0.2.0.0
  routers:
    - area: 1.0.0.0
      bits:
        B: 0
        E: 1
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.1.2
          metric: 10
          routerid: 0.1.0.0
          type: transit
        - address: 0.0.2.2
          interface: 0.0.2.2
          metric: 10
          routerid: 0.2.0.0
          type: transit
      routerid: 0.2.0.0
  summarys:
    - address: 0.0.3.0
      area: 1.0.0.0
      metric: 10
      prefixaddress: 3::0
      prefixlength: 64
      routerid: 0.1.0.0
  boundarys:
    - address: 0.0.1.0
      area: 1.0.0.0
      asbrouter: 0.4.0.0
      metric: 10
      routerid: 0.1.0.0
  externals:
    - address: 0.0.5.0
      metric: 10
      prefixaddress: 5::0
      prefixlength: 64
      routerid: 0.1.0.0
      type: 1
self:
  areas:
    - 1.0.0.0
  routerid: 0.2.0.0
EOF
},

{
id => "router.10",
text => "Missing router in area.",
errors => [
"Network 0.0.2.1\@0.1.0.0 and router 0.1.0.0 not in same area 2.0.0.0.",
],
colors => { black => 1, orange => 1, },
clusters => {},
options => "-bse",
yaml => <<EOF,
---
database:
  networks:
    - address: 0.0.1.1
      area: 1.0.0.0
      attachments:
        - routerid: 0.1.0.0
        - routerid: 0.2.0.0
      routerid: 0.1.0.0
    - address: 0.0.2.1
      area: 2.0.0.0
      attachments:
        - routerid: 0.1.0.0
        - routerid: 0.2.0.0
      routerid: 0.1.0.0
  routers:
    - area: 1.0.0.0
      bits:
        B: 1
        E: 1
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.1.1
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.1.0.0
    - area: 1.0.0.0
      bits:
        B: 1
        E: 1
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.1.2
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.2.0.0
    - area: 2.0.0.0
      bits:
        B: 1
        E: 1
        V: 0
      links:
        - address: 0.0.2.1
          interface: 0.0.2.2
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.2.0.0
self:
  areas:
    - 1.0.0.0
    - 2.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "router.11",
text => "Missing router in area not boundary.",
errors => [
"Network 0.0.2.1\@0.1.0.0 and router 0.1.0.0 not in same area 2.0.0.0.",
],
colors => { black => 1, orange => 1, },
clusters => {},
options => "-bse",
yaml => <<EOF,
---
database:
  networks:
    - address: 0.0.1.1
      area: 1.0.0.0
      attachments:
        - routerid: 0.1.0.0
        - routerid: 0.2.0.0
      routerid: 0.1.0.0
    - address: 0.0.2.1
      area: 2.0.0.0
      attachments:
        - routerid: 0.1.0.0
        - routerid: 0.2.0.0
      routerid: 0.1.0.0
  routers:
    - area: 1.0.0.0
      bits:
        B: 0
        E: 1
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.1.1
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.1.0.0
    - area: 1.0.0.0
      bits:
        B: 1
        E: 1
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.1.2
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.2.0.0
    - area: 2.0.0.0
      bits:
        B: 1
        E: 1
        V: 0
      links:
        - address: 0.0.2.1
          interface: 0.0.2.2
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.2.0.0
self:
  areas:
    - 1.0.0.0
    - 2.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "router.12",
text => "Missing router multiple for network attachment.",
errors => [
"Router 0.2.0.0 missing.",
],
colors => { red => 1, },
clusters => {},
options => "-bse",
yaml => <<EOF,
---
database:
  networks:
    - address: 0.0.1.1
      area: 1.0.0.0
      attachments:
        - routerid: 0.1.0.0
        - routerid: 0.2.0.0
      routerid: 0.1.0.0
    - address: 0.0.2.2
      area: 2.0.0.0
      attachments:
        - routerid: 0.2.0.0
        - routerid: 0.3.0.0
      routerid: 0.2.0.0
  routers:
    - area: 1.0.0.0
      bits:
        B: 0
        E: 1
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.1.1
          metric: 10
          routerid: 0.1.0.0
          type: transit
      routerid: 0.1.0.0
    - area: 2.0.0.0
      bits:
        B: 0
        E: 1
        V: 0
      links:
        - address: 0.0.2.2
          interface: 0.0.2.3
          metric: 10
          routerid: 0.2.0.0
          type: transit
      routerid: 0.3.0.0
self:
  areas:
    - 1.0.0.0
    - 2.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "router.13",
text => "Remove ASB router.",
errors => [],
colors => { black => 1, },
clusters => {},
options => "-bse",
yaml => <<EOF,
---
database:
  boundarys:
    - address: 0.0.1.0
      area: 1.0.0.0
      asbrouter: 0.3.0.0
      metric: 31
      routerid: 0.1.0.0
    - address: 0.0.2.0
      area: 2.0.0.0
      asbrouter: 0.3.0.0
      metric: 32
      routerid: 0.2.0.0
    - address: 0.0.3.0
      area: 1.0.0.0
      asbrouter: 0.4.0.0
      metric: 41
      routerid: 0.1.0.0
    - address: 0.0.4.0
      area: 2.0.0.0
      asbrouter: 0.4.0.0
      metric: 42
      routerid: 0.2.0.0
  routers:
    - area: 1.0.0.0
      bits:
        B: 0
        E: 1
        V: 0
      links:
      routerid: 0.1.0.0
    - area: 2.0.0.0
      bits:
        B: 0
        E: 1
        V: 0
      links:
      routerid: 0.2.0.0
    - area: 3.0.0.0
      bits:
        B: 0
        E: 1
        V: 0
      links:
      routerid: 0.3.0.0
self:
  areas:
    - 1.0.0.0
    - 2.0.0.0
    - 3.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "summary.0",
text => "Multiple summary networks, no error.",
errors => [],
colors => { black => 3, },
clusters => {},
options => "-bse",
yaml => <<EOF,
---
database:
  networks:
    - address: 0.0.2.2
      area: 2.0.0.0
      attachments:
        - routerid: 0.1.0.0
        - routerid: 0.2.0.0
      routerid: 0.2.0.0
    - address: 0.0.3.3
      area: 3.0.0.0
      attachments:
        - routerid: 0.1.0.0
        - routerid: 0.3.0.0
      routerid: 0.3.0.0
  routers:
    - area: 1.0.0.0
      bits:
        B: 1
        E: 1
        V: 0
      links:
      routerid: 0.1.0.0
    - area: 2.0.0.0
      bits:
        B: 1
        E: 1
        V: 0
      links:
        - address: 0.0.2.2
          interface: 0.0.2.1
          metric: 10
          routerid: 0.2.0.0
          type: transit
      routerid: 0.1.0.0
    - area: 2.0.0.0
      bits:
        B: 1
        E: 1
        V: 0
      links:
        - address: 0.0.2.2
          interface: 0.0.2.2
          metric: 10
          routerid: 0.2.0.0
          type: transit
      routerid: 0.2.0.0
    - area: 3.0.0.0
      bits:
        B: 1
        E: 1
        V: 0
      links:
        - address: 0.0.3.3
          interface: 0.0.3.1
          metric: 10
          routerid: 0.3.0.0
          type: transit
      routerid: 0.1.0.0
    - area: 3.0.0.0
      bits:
        B: 1
        E: 1
        V: 0
      links:
        - address: 0.0.3.3
          interface: 0.0.3.3
          metric: 10
          routerid: 0.3.0.0
          type: transit
      routerid: 0.3.0.0
  summarys:
    - address: 0.0.1.0
      area: 1.0.0.0
      metric: 10
      prefixaddress: 3::0
      prefixlength: 64
      routerid: 0.1.0.0
    - address: 0.0.2.0
      area: 1.0.0.0
      metric: 10
      prefixaddress: 2::0
      prefixlength: 64
      routerid: 0.1.0.0
    - address: 0.0.3.0
      area: 2.0.0.0
      metric: 10
      prefixaddress: 3::0
      prefixlength: 64
      routerid: 0.1.0.0
    - address: 0.0.4.0
      area: 3.0.0.0
      metric: 10
      prefixaddress: 2::0
      prefixlength: 64
      routerid: 0.1.0.0
self:
  areas:
    - 1.0.0.0
    - 2.0.0.0
    - 3.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "summary.3",
text => "Summary network and router same area.",
errors => [
"Summary network 1::0/64 and router 0.1.0.0 not in same area 2.0.0.0.",
],
colors => { black => 1, orange => 1, },
clusters => {},
options => "-bse",
yaml => <<EOF,
---
database:
  routers:
    - area: 1.0.0.0
      bits:
        B: 1
        E: 1
        V: 0
      links:
      routerid: 0.1.0.0
  summarys:
    - address: 0.0.1.0
      area: 1.0.0.0
      metric: 10
      prefixaddress: 1::0
      prefixlength: 64
      routerid: 0.1.0.0
    - address: 0.0.2.0
      area: 2.0.0.0
      metric: 10
      prefixaddress: 1::0
      prefixlength: 64
      routerid: 0.1.0.0
self:
  areas:
    - 1.0.0.0
    - 2.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "summary.4",
text => "Summary network multiple entries.",
errors => [
"Summary network 1::0/64 at router 0.1.0.0 has multiple entries in area 1.0.0.0.",
"Summary network 1::0/64 at router 0.1.0.0 has multiple entries in area 1.0.0.0.",
],
colors => { black => 2, yellow => 2, },
clusters => {},
options => "-bse",
yaml => <<EOF,
---
database:
  routers:
    - area: 1.0.0.0
      bits:
        B: 1
        E: 1
        V: 0
      links:
      routerid: 0.1.0.0
    - area: 2.0.0.0
      bits:
        B: 1
        E: 1
        V: 0
      links:
      routerid: 0.1.0.0
  summarys:
    - address: 0.0.1.0
      area: 1.0.0.0
      metric: 10
      prefixaddress: 1::0
      prefixlength: 64
      routerid: 0.1.0.0
    - address: 0.0.2.0
      area: 1.0.0.0
      metric: 10
      prefixaddress: 1::0
      prefixlength: 64
      routerid: 0.1.0.0
    - address: 0.0.3.0
      area: 2.0.0.0
      prefixaddress: 1::0
      prefixlength: 64
      metric: 10
      routerid: 0.1.0.0
self:
  areas:
    - 1.0.0.0
    - 2.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "summary.5",
text => "Summary network multiple link state IDs.",
errors => [
"Summary network 1::0/64 at router 0.1.0.0 has multiple entries in area 1.0.0.0.",
"Summary network 1::0/64 at router 0.1.0.0 has multiple entries in area 1.0.0.0.",
"Summary network 1::0/64 at router 0.1.0.0 has multiple link state IDs 0.0.1.0 in area 1.0.0.0.",
"Summary network 1::0/64 at router 0.1.0.0 has multiple link state IDs 0.0.1.0 in area 1.0.0.0.",
"Summary network 2::0/64 at router 0.1.0.0 has multiple link state IDs 0.0.2.0 in area 1.0.0.0.",
"Summary network 3::0/64 at router 0.1.0.0 has multiple link state IDs 0.0.2.0 in area 1.0.0.0.",
],
colors => { black => 2, magenta => 4, },
clusters => {},
options => "-bse",
yaml => <<EOF,
---
database:
  routers:
    - area: 1.0.0.0
      bits:
        B: 1
        E: 1
        V: 0
      links:
      routerid: 0.1.0.0
    - area: 2.0.0.0
      bits:
        B: 1
        E: 1
        V: 0
      links:
      routerid: 0.1.0.0
    - area: 1.0.0.0
      bits:
        B: 0
        E: 1
        V: 0
      links:
      routerid: 0.2.0.0
  summarys:
    - address: 0.0.1.0
      area: 1.0.0.0
      metric: 10
      prefixaddress: 1::0
      prefixlength: 64
      routerid: 0.1.0.0
    - address: 0.0.1.0
      area: 1.0.0.0
      metric: 10
      prefixaddress: 1::0
      prefixlength: 64
      routerid: 0.1.0.0
    - address: 0.0.2.0
      area: 1.0.0.0
      metric: 10
      prefixaddress: 2::0
      prefixlength: 64
      routerid: 0.1.0.0
    - address: 0.0.2.0
      area: 1.0.0.0
      metric: 10
      prefixaddress: 3::0
      prefixlength: 64
      routerid: 0.1.0.0
    - address: 0.0.2.0
      area: 2.0.0.0
      metric: 10
      prefixaddress: 3::0
      prefixlength: 64
      routerid: 0.1.0.0
    - address: 0.0.2.0
      area: 1.0.0.0
      metric: 10
      prefixaddress: 2::0
      prefixlength: 64
      routerid: 0.2.0.0
self:
  areas:
    - 1.0.0.0
    - 2.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "boundary.0",
text => "Multiple boundary rounters, no error.",
errors => [],
colors => { black => 2, },
clusters => {},
options => "-bse",
yaml => <<EOF,
---
database:
  boundarys:
    - address: 0.0.1.0
      area: 1.0.0.0
      asbrouter: 0.3.0.0
      metric: 10
      routerid: 0.1.0.0
    - address: 0.0.2.0
      area: 2.0.0.0
      asbrouter: 0.4.0.0
      metric: 10
      routerid: 0.1.0.0
    - address: 0.0.3.0
      area: 2.0.0.0
      asbrouter: 0.5.0.0
      metric: 10
      routerid: 0.2.0.0
    - address: 0.0.4.0
      area: 3.0.0.0
      asbrouter: 0.4.0.0
      metric: 10
      routerid: 0.1.0.0
  networks:
    - address: 0.0.2.2
      area: 2.0.0.0
      attachments:
        - routerid: 0.1.0.0
        - routerid: 0.2.0.0
      routerid: 0.2.0.0
    - address: 0.0.3.3
      area: 3.0.0.0
      attachments:
        - routerid: 0.1.0.0
        - routerid: 0.3.0.0
      routerid: 0.3.0.0
  routers:
    - area: 1.0.0.0
      bits:
        B: 1
        E: 1
        V: 0
      links:
      routerid: 0.1.0.0
    - area: 2.0.0.0
      bits:
        B: 1
        E: 1
        V: 0
      links:
        - address: 0.0.2.2
          interface: 0.0.2.1
          metric: 10
          routerid: 0.2.0.0
          type: transit
      routerid: 0.1.0.0
    - area: 2.0.0.0
      bits:
        B: 0
        E: 1
        V: 0
      links:
        - address: 0.0.2.2
          interface: 0.0.2.2
          metric: 10
          routerid: 0.2.0.0
          type: transit
      routerid: 0.2.0.0
    - area: 3.0.0.0
      bits:
        B: 1
        E: 1
        V: 0
      links:
        - address: 0.0.3.3
          interface: 0.0.3.1
          metric: 10
          routerid: 0.3.0.0
          type: transit
      routerid: 0.1.0.0
    - area: 3.0.0.0
      bits:
        B: 0
        E: 1
        V: 0
      links:
        - address: 0.0.3.3
          interface: 0.0.3.3
          metric: 10
          routerid: 0.3.0.0
          type: transit
      routerid: 0.3.0.0
self:
  areas:
    - 1.0.0.0
    - 2.0.0.0
    - 3.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "boundary.1",
text => "Boundary router is also router in same area.",
errors => [
"AS boundary router 0.2.0.0 is router in same area 1.0.0.0.",
],
colors => { blue => 1, },
clusters => {},
options => "-bse",
yaml => <<EOF,
---
database:
  boundarys:
    - address: 0.0.1.0
      area: 1.0.0.0
      asbrouter: 0.2.0.0
      metric: 10
      routerid: 0.1.0.0
  routers:
    - area: 1.0.0.0
      bits:
        B: 0
        E: 1
        V: 0
      links:
      routerid: 0.1.0.0
    - area: 1.0.0.0
      bits:
        B: 0
        E: 1
        V: 0
      links:
      routerid: 0.2.0.0
self:
  areas:
    - 1.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "boundary.2",
text => "Boundary router not in same area.",
errors => [
"AS boundary router 0.2.0.0 and router 0.1.0.0 not in same area 3.0.0.0.",
"AS boundary router 0.3.0.0 and router 0.1.0.0 not in same area 3.0.0.0.",
],
colors => { black => 2, orange => 2, },
clusters => {},
options => "-bse",
yaml => <<EOF,
---
database:
  boundarys:
    - address: 0.0.1.0
      area: 1.0.0.0
      asbrouter: 0.2.0.0
      metric: 10
      routerid: 0.1.0.0
    - address: 0.0.2.0
      area: 2.0.0.0
      asbrouter: 0.3.0.0
      metric: 10
      routerid: 0.1.0.0
    - address: 0.0.3.0
      area: 3.0.0.0
      asbrouter: 0.2.0.0
      metric: 10
      routerid: 0.1.0.0
    - address: 0.0.4.0
      area: 3.0.0.0
      asbrouter: 0.3.0.0
      metric: 10
      routerid: 0.1.0.0
  networks:
    - address: 0.0.2.2
      area: 2.0.0.0
      attachments:
        - routerid: 0.1.0.0
        - routerid: 0.2.0.0
      routerid: 0.2.0.0
  routers:
    - area: 1.0.0.0
      bits:
        B: 1
        E: 1
        V: 0
      links:
      routerid: 0.1.0.0
    - area: 2.0.0.0
      bits:
        B: 1
        E: 1
        V: 0
      links:
        - address: 0.0.2.2
          interface: 0.0.2.1
          metric: 10
          routerid: 0.2.0.0
          type: transit
      routerid: 0.1.0.0
    - area: 2.0.0.0
      bits:
        B: 0
        E: 1
        V: 0
      links:
        - address: 0.0.2.2
          interface: 0.0.2.2
          metric: 10
          routerid: 0.2.0.0
          type: transit
      routerid: 0.2.0.0
self:
  areas:
    - 1.0.0.0
    - 2.0.0.0
    - 3.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "boundary.3",
text => "Boundary router multiple entries.",
errors => [
"AS boundary router 0.2.0.0 at router 0.1.0.0 has multiple entries in area 1.0.0.0.",
"AS boundary router 0.2.0.0 at router 0.1.0.0 has multiple entries in area 1.0.0.0.",
"AS boundary router 0.3.0.0 at router 0.1.0.0 has multiple entries in area 2.0.0.0.",
"AS boundary router 0.3.0.0 at router 0.1.0.0 has multiple entries in area 2.0.0.0.",
],
colors => { black => 2, yellow => 4, },
clusters => {},
options => "-bse",
yaml => <<EOF,
---
database:
  boundarys:
    - address: 0.0.1.0
      area: 1.0.0.0
      asbrouter: 0.2.0.0
      metric: 10
      routerid: 0.1.0.0
    - address: 0.0.2.0
      area: 1.0.0.0
      asbrouter: 0.2.0.0
      metric: 10
      routerid: 0.1.0.0
    - address: 0.0.3.0
      area: 2.0.0.0
      asbrouter: 0.3.0.0
      metric: 10
      routerid: 0.1.0.0
    - address: 0.0.4.0
      area: 2.0.0.0
      asbrouter: 0.3.0.0
      metric: 10
      routerid: 0.1.0.0
    - address: 0.0.5.0
      area: 3.0.0.0
      asbrouter: 0.2.0.0
      metric: 10
      routerid: 0.1.0.0
    - address: 0.0.6.0
      area: 3.0.0.0
      asbrouter: 0.3.0.0
      metric: 10
      routerid: 0.1.0.0
  networks:
    - address: 0.0.2.2
      area: 2.0.0.0
      attachments:
        - routerid: 0.1.0.0
        - routerid: 0.2.0.0
      routerid: 0.2.0.0
  routers:
    - area: 1.0.0.0
      bits:
        B: 1
        E: 1
        V: 0
      links:
      routerid: 0.1.0.0
    - area: 2.0.0.0
      bits:
        B: 1
        E: 1
        V: 0
      links:
        - address: 0.0.2.2
          interface: 0.0.2.1
          metric: 10
          routerid: 0.2.0.0
          type: transit
      routerid: 0.1.0.0
    - area: 2.0.0.0
      bits:
        B: 0
        E: 1
        V: 0
      links:
        - address: 0.0.2.2
          interface: 0.0.2.2
          metric: 10
          routerid: 0.2.0.0
          type: transit
      routerid: 0.2.0.0
    - area: 3.0.0.0
      bits:
        B: 1
        E: 1
        V: 0
      links:
      routerid: 0.1.0.0
self:
  areas:
    - 1.0.0.0
    - 2.0.0.0
    - 3.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "boundary.4",
text => "Boundary router advertized by itself.",
errors => [
"AS boundary router 0.1.0.0 is advertized by itself in area 1.0.0.0.",
],
colors => { brown => 1, },
clusters => {},
options => "-bse",
yaml => <<EOF,
---
database:
  boundarys:
    - address: 0.0.1.0
      area: 1.0.0.0
      asbrouter: 0.1.0.0
      metric: 10
      routerid: 0.1.0.0
  routers:
    - area: 1.0.0.0
      bits:
        B: 1
        E: 0
        V: 0
      links:
      routerid: 0.1.0.0
self:
  areas:
    - 1.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "boundary.5",
text => "Boundary router multiple link state IDs.",
errors => [
"AS boundary router 0.3.0.0 at router 0.1.0.0 has multiple entries in area 1.0.0.0.",
"AS boundary router 0.3.0.0 at router 0.1.0.0 has multiple entries in area 1.0.0.0.",
"AS boundary router 0.3.0.0 at router 0.1.0.0 has multiple link state IDs 0.0.1.0 in area 1.0.0.0.",
"AS boundary router 0.3.0.0 at router 0.1.0.0 has multiple link state IDs 0.0.1.0 in area 1.0.0.0.",
"AS boundary router 0.4.0.0 at router 0.1.0.0 has multiple link state IDs 0.0.2.0 in area 1.0.0.0.",
"AS boundary router 0.5.0.0 at router 0.1.0.0 has multiple link state IDs 0.0.2.0 in area 1.0.0.0.",
],
colors => { black => 2, magenta => 4, },
clusters => {},
options => "-bse",
yaml => <<EOF,
---
database:
  boundarys:
    - address: 0.0.1.0
      area: 1.0.0.0
      asbrouter: 0.3.0.0
      metric: 10
      routerid: 0.1.0.0
    - address: 0.0.1.0
      area: 1.0.0.0
      asbrouter: 0.3.0.0
      metric: 10
      routerid: 0.1.0.0
    - address: 0.0.2.0
      area: 1.0.0.0
      asbrouter: 0.4.0.0
      metric: 10
      routerid: 0.1.0.0
    - address: 0.0.2.0
      area: 1.0.0.0
      asbrouter: 0.5.0.0
      metric: 10
      routerid: 0.1.0.0
    - address: 0.0.2.0
      area: 2.0.0.0
      asbrouter: 0.5.0.0
      metric: 10
      routerid: 0.1.0.0
    - address: 0.0.2.0
      area: 1.0.0.0
      asbrouter: 0.4.0.0
      metric: 10
      routerid: 0.2.0.0
  routers:
    - area: 1.0.0.0
      bits:
        B: 1
        E: 1
        V: 0
      links:
      routerid: 0.1.0.0
    - area: 2.0.0.0
      bits:
        B: 1
        E: 1
        V: 0
      links:
      routerid: 0.1.0.0
    - area: 1.0.0.0
      bits:
        B: 0
        E: 1
        V: 0
      links:
      routerid: 0.2.0.0
self:
  areas:
    - 1.0.0.0
    - 2.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "external.0",
text => "Multiple external rounters, no error.",
errors => [],
colors => { black => 1, },
clusters => {},
options => "-bse",
yaml => <<EOF,
---
database:
  boundarys:
    - address: 0.0.1.0
      area: 1.0.0.0
      asbrouter: 0.2.0.0
      metric: 10
      routerid: 0.1.0.0
    - address: 0.0.2.0
      area: 2.0.0.0
      asbrouter: 0.3.0.0
      metric: 10
      routerid: 0.1.0.0
  externals:
    - address: 0.0.1.0
      metric: 20
      prefixaddress: 1::0
      prefixlength: 96
      routerid: 0.1.0.0
      type: 1
    - address: 0.0.2.255
      metric: 20
      prefixaddress: 2::0
      prefixlength: 96
      routerid: 0.2.0.0
      type: 1
    - address: 0.0.3.0
      metric: 20
      prefixaddress: 3::0
      prefixlength: 96
      routerid: 0.3.0.0
      type: 1
    - address: 0.0.4.255
      metric: 20
      prefixaddress: 4::0
      prefixlength: 96
      routerid: 0.1.0.0
      type: 1
    - address: 0.0.4.255
      metric: 20
      prefixaddress: 4::0
      prefixlength: 96
      routerid: 0.2.0.0
      type: 2
    - address: 0.0.4.128
      metric: 20
      prefixaddress: 4::0
      prefixlength: 96
      routerid: 0.3.0.0
      type: 2
  networks:
    - address: 0.0.2.2
      area: 2.0.0.0
      attachments:
        - routerid: 0.1.0.0
        - routerid: 0.2.0.0
      routerid: 0.2.0.0
  routers:
    - area: 1.0.0.0
      bits:
        B: 1
        E: 1
        V: 0
      links:
      routerid: 0.1.0.0
    - area: 2.0.0.0
      bits:
        B: 1
        E: 1
        V: 0
      links:
        - address: 0.0.2.2
          interface: 0.0.2.1
          metric: 10
          routerid: 0.2.0.0
          type: transit
      routerid: 0.1.0.0
    - area: 2.0.0.0
      bits:
        B: 0
        E: 1
        V: 0
      links:
        - address: 0.0.2.2
          interface: 0.0.2.2
          metric: 10
          routerid: 0.2.0.0
          type: transit
      routerid: 0.2.0.0
self:
  areas:
    - 1.0.0.0
    - 2.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "external.2",
text => "External network has multiple entries.",
errors => [
"AS external network 1::0/64 at router 0.1.0.0 has multiple entries.",
"AS external network 1::0/64 at router 0.1.0.0 has multiple entries.",
"AS external network 1::0/64 at router 0.1.0.0 has multiple entries.",
"AS external network 1::0/64 at router 0.3.0.0 has multiple entries.",
"AS external network 1::0/64 at router 0.3.0.0 has multiple entries.",
],
colors => { yellow => 5, },
clusters => {},
options => "-bse",
yaml => <<EOF,
---
database:
  boundarys:
    - address: 0.0.1.0
      area: 1.0.0.0
      asbrouter: 0.3.0.0
      metric: 10
      routerid: 0.1.0.0
  externals:
    - address: 0.0.1.0
      metric: 20
      prefixaddress: 1::0
      prefixlength: 64
      routerid: 0.1.0.0
      type: 1
    - address: 0.0.2.0
      metric: 20
      prefixaddress: 1::0
      prefixlength: 64
      routerid: 0.1.0.0
      type: 1
    - address: 0.0.3.0
      metric: 20
      prefixaddress: 1::0
      prefixlength: 64
      routerid: 0.1.0.0
      type: 2
    - address: 0.0.4.0
      metric: 20
      prefixaddress: 1::0
      prefixlength: 64
      routerid: 0.2.0.0
      type: 1
    - address: 0.0.5.0
      metric: 20
      prefixaddress: 1::0
      prefixlength: 64
      routerid: 0.3.0.0
      type: 1
    - address: 0.0.6.0
      metric: 20
      prefixaddress: 1::0
      prefixlength: 64
      routerid: 0.3.0.0
      type: 1
  routers:
    - area: 1.0.0.0
      bits:
        B: 0
        E: 1
        V: 0
      links:
      routerid: 0.1.0.0
    - area: 1.0.0.0
      bits:
        B: 0
        E: 1
        V: 0
      links:
      routerid: 0.2.0.0
self:
  areas:
    - 1.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "external.3",
text => "External network has multiple link state IDs.",
errors => [
"AS external network 1::0/64 at router 0.1.0.0 has multiple entries.",
"AS external network 1::0/64 at router 0.1.0.0 has multiple entries.",
"AS external network 1::0/64 at router 0.1.0.0 has multiple link state IDs 0.0.1.0.",
"AS external network 1::0/64 at router 0.1.0.0 has multiple link state IDs 0.0.1.0.",
"AS external network 2::0/64 at router 0.2.0.0 has multiple link state IDs 0.0.2.0.",
"AS external network 3::0/64 at router 0.2.0.0 has multiple link state IDs 0.0.2.0.",
"AS external network 3::0/64 at router 0.3.0.0 has multiple link state IDs 0.0.3.0.",
"AS external network 4::0/64 at router 0.3.0.0 has multiple link state IDs 0.0.3.0.",
"AS external network 5::0/64 at router 0.3.0.0 has multiple link state IDs 0.0.3.0.",
],
colors => { magenta => 7, },
clusters => {},
options => "-bse",
yaml => <<EOF,
---
database:
  boundarys:
    - address: 0.0.1.0
      area: 1.0.0.0
      asbrouter: 0.3.0.0
      metric: 10
      routerid: 0.1.0.0
  externals:
    - address: 0.0.1.0
      metric: 20
      prefixaddress: 1::0
      prefixlength: 64
      routerid: 0.1.0.0
      type: 1
    - address: 0.0.1.0
      metric: 20
      prefixaddress: 1::0
      prefixlength: 64
      routerid: 0.1.0.0
      type: 1
    - address: 0.0.1.0
      metric: 20
      prefixaddress: 1::0
      prefixlength: 64
      routerid: 0.2.0.0
      type: 1
    - address: 0.0.2.0
      metric: 20
      prefixaddress: 2::0
      prefixlength: 64
      routerid: 0.2.0.0
      type: 1
    - address: 0.0.2.0
      metric: 20
      prefixaddress: 3::0
      prefixlength: 64
      routerid: 0.2.0.0
      type: 1
    - address: 0.0.3.0
      metric: 20
      prefixaddress: 4::0
      prefixlength: 64
      routerid: 0.3.0.0
      type: 1
    - address: 0.0.3.0
      metric: 20
      prefixaddress: 5::0
      prefixlength: 64
      routerid: 0.3.0.0
      type: 1
    - address: 0.0.1.0
      metric: 20
      prefixaddress: 1::0
      prefixlength: 64
      routerid: 0.3.0.0
      type: 1
    - address: 0.0.2.0
      metric: 20
      prefixaddress: 2::0
      prefixlength: 64
      routerid: 0.3.0.0
      type: 1
    - address: 0.0.3.0
      metric: 20
      prefixaddress: 3::0
      prefixlength: 64
      routerid: 0.3.0.0
      type: 1
  routers:
    - area: 1.0.0.0
      bits:
        B: 0
        E: 1
        V: 0
      links:
      routerid: 0.1.0.0
    - area: 1.0.0.0
      bits:
        B: 0
        E: 1
        V: 0
      links:
      routerid: 0.2.0.0
self:
  areas:
    - 1.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "point.0",
text => "Two routers with point-to-point link.",
errors => [],
colors => {},
clusters => {},
options => "",
yaml => <<EOF,
---
database:
  routers:
    - area: 1.0.0.0
      bits:
        B: 1
        E: 0
        V: 0
      links:
        - address: 0.0.1.2
          interface: 0.0.1.1
          metric: 1
          routerid: 0.2.0.0
          type: pointtopoint
      routerid: 0.1.0.0
    - area: 1.0.0.0
      bits:
        B: 1
        E: 0
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.1.2
          metric: 1
          routerid: 0.1.0.0
          type: pointtopoint
      routerid: 0.2.0.0
self:
  areas:
    - 1.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "point.1",
text => "Routers with duplicate point-to-point link.",
errors => [
"Point-to-point link at router 0.1.0.0 to router 0.2.0.0 has multiple entries in area 1.0.0.0.",
],
colors => { yellow => 2, },
clusters => {},
options => "",
yaml => <<EOF,
---
database:
  routers:
    - area: 1.0.0.0
      bits:
        B: 1
        E: 0
        V: 0
      links:
        - address: 0.0.1.2
          interface: 0.0.1.1
          metric: 1
          routerid: 0.2.0.0
          type: pointtopoint
        - address: 0.0.1.2
          interface: 0.0.1.3
          metric: 1
          routerid: 0.2.0.0
          type: pointtopoint
      routerid: 0.1.0.0
    - area: 1.0.0.0
      bits:
        B: 1
        E: 0
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.1.2
          metric: 1
          routerid: 0.1.0.0
          type: pointtopoint
      routerid: 0.2.0.0
self:
  areas:
    - 1.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "point.2",
text => "Two routers with point-to-point link in different areas.",
errors => [
"Point-to-point link at router 0.1.0.0 to router 0.2.0.0 not in same area 1.0.0.0.",
"Point-to-point link at router 0.2.0.0 to router 0.1.0.0 not in same area 2.0.0.0.",
],
colors => { orange => 2, },
clusters => {},
options => "",
yaml => <<EOF,
---
database:
  routers:
    - area: 1.0.0.0
      bits:
        B: 1
        E: 0
        V: 0
      links:
        - address: 0.0.1.2
          interface: 0.0.1.1
          metric: 1
          routerid: 0.2.0.0
          type: pointtopoint
      routerid: 0.1.0.0
    - area: 2.0.0.0
      bits:
        B: 1
        E: 0
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.1.2
          metric: 1
          routerid: 0.1.0.0
          type: pointtopoint
      routerid: 0.2.0.0
self:
  areas:
    - 1.0.0.0
    - 2.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "point.3",
text => "Router with point-to-point link to nonexisting router.",
errors => [
"Router 0.2.0.0 missing.",
],
colors => { red => 1, },
clusters => {},
options => "",
yaml => <<EOF,
---
database:
  routers:
    - area: 1.0.0.0
      bits:
        B: 1
        E: 0
        V: 0
      links:
        - address: 0.0.1.2
          interface: 0.0.1.1
          metric: 1
          routerid: 0.2.0.0
          type: pointtopoint
      routerid: 0.1.0.0
self:
  areas:
    - 1.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "point.4",
text => "Point-to-point link reuses interface address at router.",
errors => [
"Point-to-point link at router 0.2.0.0 to router 0.1.0.0 interface address 0.0.3.2 not unique.",
"Transit link at router 0.2.0.0 to network 0.0.3.3\@0.3.0.0 interface address 0.0.3.2 not unique.",
],
colors => { green => 2, },
clusters => {},
options => "",
yaml => <<EOF,
---
database:
  networks:
    - address: 0.0.3.3
      area: 1.0.0.0
      attachments:
        - routerid: 0.2.0.0
        - routerid: 0.3.0.0
      routerid: 0.3.0.0
  routers:
    - area: 1.0.0.0
      bits:
        B: 1
        E: 0
        V: 0
      links:
        - address: 0.0.3.2
          interface: 0.0.1.1
          metric: 1
          routerid: 0.2.0.0
          type: pointtopoint
      routerid: 0.1.0.0
    - area: 1.0.0.0
      bits:
        B: 1
        E: 0
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.3.2
          metric: 1
          routerid: 0.1.0.0
          type: pointtopoint
        - address: 0.0.3.3
          interface: 0.0.3.2
          metric: 10
          routerid: 0.3.0.0
          type: transit
      routerid: 0.2.0.0
    - area: 1.0.0.0
      bits:
        B: 1
        E: 0
        V: 0
      links:
        - address: 0.0.3.3
          interface: 0.0.3.3
          metric: 10
          routerid: 0.3.0.0
          type: transit
      routerid: 0.3.0.0
self:
  areas:
    - 1.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "point.5",
text => "Point-to-point link reuses interface address.",
errors => [],
colors => {},
clusters => {},
options => "",
yaml => <<EOF,
---
database:
  networks:
    - address: 0.0.3.3
      area: 1.0.0.0
      attachments:
        - routerid: 0.2.0.0
        - routerid: 0.3.0.0
      routerid: 0.3.0.0
  routers:
    - area: 1.0.0.0
      bits:
        B: 1
        E: 0
        V: 0
      links:
        - address: 0.0.1.2
          interface: 0.0.3.3
          metric: 1
          routerid: 0.2.0.0
          type: pointtopoint
      routerid: 0.1.0.0
    - area: 1.0.0.0
      bits:
        B: 1
        E: 0
        V: 0
      links:
        - address: 0.0.3.3
          interface: 0.0.1.2
          metric: 1
          routerid: 0.1.0.0
          type: pointtopoint
        - address: 0.0.3.3
          interface: 0.0.3.2
          metric: 10
          routerid: 0.3.0.0
          type: transit
      routerid: 0.2.0.0
    - area: 1.0.0.0
      bits:
        B: 1
        E: 0
        V: 0
      links:
        - address: 0.0.3.3
          interface: 0.0.3.3
          metric: 10
          routerid: 0.3.0.0
          type: transit
      routerid: 0.3.0.0
self:
  areas:
    - 1.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "point.6",
text => "Point-to-point link not symmetric.",
errors => [
"Point-to-point link at router 0.1.0.0 to router 0.2.0.0 not symmetric in area 1.0.0.0.",
],
colors => { brown => 1, },
clusters => {},
options => "",
yaml => <<EOF,
---
database:
  routers:
    - area: 1.0.0.0
      bits:
        B: 1
        E: 0
        V: 0
      links:
        - address: 0.0.1.2
          interface: 0.0.1.1
          metric: 24
          routerid: 0.2.0.0
          type: pointtopoint
      routerid: 0.1.0.0
    - area: 1.0.0.0
      bits:
        B: 1
        E: 0
        V: 1
      links:
      routerid: 0.2.0.0
self:
  areas:
    - 1.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "virtual.0",
text => "Two routers with virtual link.",
errors => [],
colors => {},
clusters => {},
options => "",
yaml => <<EOF,
---
database:
  routers:
    - area: 1.0.0.0
      bits:
        B: 1
        E: 0
        V: 0
      links:
        - address: 0.0.2.2
          interface: 0.0.1.1
          metric: 24
          routerid: 0.2.0.0
          type: virtual
      routerid: 0.1.0.0
    - area: 1.0.0.0
      bits:
        B: 1
        E: 0
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.2.2
          metric: 12
          routerid: 0.1.0.0
          type: virtual
      routerid: 0.2.0.0
self:
  areas:
    - 1.0.0.0
    - 2.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "virtual.1",
text => "Two routers with duplicate virtual link.",
errors => [
"Virtual link at router 0.1.0.0 to router 0.2.0.0 has multiple entries in area 1.0.0.0.",
],
colors => { yellow => 2, },
clusters => {},
options => "",
yaml => <<EOF,
---
database:
  routers:
    - area: 1.0.0.0
      bits:
        B: 1
        E: 0
        V: 0
      links:
        - address: 0.0.2.2
          interface: 0.0.1.1
          metric: 24
          routerid: 0.2.0.0
          type: virtual
        - address: 0.0.2.2
          interface: 0.0.1.1
          metric: 24
          routerid: 0.2.0.0
          type: virtual
      routerid: 0.1.0.0
    - area: 1.0.0.0
      bits:
        B: 1
        E: 0
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.2.2
          metric: 12
          routerid: 0.1.0.0
          type: virtual
      routerid: 0.2.0.0
self:
  areas:
    - 1.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "virtual.2",
text => "Two routers with virtual link in different areas.",
errors => [
"Virtual link at router 0.1.0.0 to router 0.2.0.0 not in same area 1.0.0.0.",
"Virtual link at router 0.2.0.0 to router 0.1.0.0 not in same area 2.0.0.0.",
],
colors => { orange => 2, },
clusters => {},
options => "",
yaml => <<EOF,
---
database:
  routers:
    - area: 1.0.0.0
      bits:
        B: 1
        E: 0
        V: 0
      links:
        - address: 0.0.2.2
          interface: 0.0.1.1
          metric: 24
          routerid: 0.2.0.0
          type: virtual
      routerid: 0.1.0.0
    - area: 2.0.0.0
      bits:
        B: 1
        E: 0
        V: 0
      links:
        - address: 0.0.1.1
          interface: 0.0.2.2
          metric: 12
          routerid: 0.1.0.0
          type: virtual
      routerid: 0.2.0.0
self:
  areas:
    - 1.0.0.0
    - 2.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "virtual.3",
text => "Routers with virtual link to nonexisting router.",
errors => [
"Router 0.2.0.0 missing.",
],
colors => { red => 1, },
clusters => {},
options => "",
yaml => <<EOF,
---
database:
  routers:
    - area: 1.0.0.0
      bits:
        B: 1
        E: 0
        V: 0
      links:
        - address: 0.0.2.2
          interface: 0.0.1.1
          metric: 24
          routerid: 0.2.0.0
          type: virtual
      routerid: 0.1.0.0
self:
  areas:
    - 1.0.0.0
  routerid: 0.1.0.0
EOF
},

{
id => "virtual.4",
text => "Virtual link not symmetric.",
errors => [
"Virtual link at router 0.1.0.0 to router 0.2.0.0 not symmetric in area 1.0.0.0.",
],
colors => { brown => 1, },
clusters => {},
options => "",
yaml => <<EOF,
---
database:
  routers:
    - area: 1.0.0.0
      bits:
        B: 1
        E: 0
        V: 1
      links:
        - address: 0.0.2.2
          interface: 0.0.1.1
          metric: 24
          routerid: 0.2.0.0
          type: virtual
      routerid: 0.1.0.0
    - area: 1.0.0.0
      bits:
        B: 1
        E: 0
        V: 1
      links:
      routerid: 0.2.0.0
self:
  areas:
    - 1.0.0.0
  routerid: 0.1.0.0
EOF
},

