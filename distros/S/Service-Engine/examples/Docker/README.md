
## Testing Guide

### Step 1
Clone repository.

```bash
git clone git@bitbucket.org:codeconvo/ns-service-engine.git

git checkout INF-41-CrateDB-Logging
```

### Step 2
Install Docker. https://drive.google.com/file/d/1UzFoIgegI3XzzJiKkun_0xAz6WMIGLvQ/view?usp=drive_link

```bash
docker compose up -d
```
### Step 3
To create initial table for logging.
```bash
docker compose exec -T cratedb crash < Docker/init/crate.sql
```

### Step 4
Run engine. 
```bash
docker compose exec -it centos /export/HTDOCS/HMLv2/examples/sampleLogging/start-engine.pl
```
