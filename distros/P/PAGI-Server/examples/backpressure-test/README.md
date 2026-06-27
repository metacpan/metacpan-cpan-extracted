# Backpressure Test App

Test application for benchmarking send-side backpressure behavior in PAGI::Server.

## Quick Start

```bash
# Start server with test endpoint enabled
PAGI_BACKPRESSURE_TEST=1 pagi-server --app examples/backpressure-test/app.pl --port 5000

# In another terminal, stream 10MB
curl -o /dev/null http://localhost:5000/stream
```

## Benchmarking

### Using curl (single connection, measure throughput)

```bash
# Stream 10MB, show progress
curl -o /dev/null -w "Time: %{time_total}s, Speed: %{speed_download} bytes/sec\n" \
    http://localhost:5000/stream

# Stream 100MB
curl -o /dev/null http://localhost:5000/stream/100

# Throttle client to 1MB/s (simulates slow client)
curl --limit-rate 1M -o /dev/null http://localhost:5000/stream/50
```

### Using hey (concurrent connections, stress test)

```bash
# Install hey: go install github.com/rakyll/hey@latest

# 50 concurrent connections, 10 seconds
hey -c 50 -z 10s http://localhost:5000/stream

# 100 concurrent connections, each downloading 10MB
hey -c 100 -n 100 http://localhost:5000/stream

# Slow clients (1 req/sec per worker, 50 workers)
hey -c 50 -q 1 -z 30s http://localhost:5000/stream/50
```

### Using wrk (high concurrency)

```bash
# 100 connections, 4 threads, 30 seconds
wrk -c 100 -t 4 -d 30s http://localhost:5000/stream
```

## Monitoring Memory

### Using top (interactive)

```bash
# Find the pagi-server process
top -pid $(pgrep -f pagi-server)

# Watch for:
# - RES/RSS column: resident memory (should stay bounded)
# - VIRT/SIZE: virtual memory
```

### Using ps (snapshot)

```bash
# Get memory usage in KB
ps -o pid,rss,vsz,comm -p $(pgrep -f pagi-server)

# Monitor every second
watch -n 1 'ps -o pid,rss,vsz,comm -p $(pgrep -f pagi-server)'
```

### Using memory profiling

```bash
# On macOS with Instruments
xcrun xctrace record --template 'Allocations' --launch -- \
    perl -Ilib bin/pagi-server --app examples/backpressure-test/app.pl

# On Linux with valgrind (slow but detailed)
valgrind --tool=massif perl -Ilib bin/pagi-server \
    --app examples/backpressure-test/app.pl
```

## Expected Behavior

### WITHOUT Backpressure (hypothetical)

If backpressure were disabled, you would observe:

1. **Memory Growth**: RSS grows unboundedly with slow clients
   - 50 slow clients × 10MB buffered = 500MB+ memory
   - Memory keeps growing until OOM or connection close

2. **Latency Spikes**: First bytes arrive fast, then stall
   - Server buffers entire response before client reads it
   - Time-to-first-byte is fast, but transfer stalls

3. **Resource Exhaustion**: Under load, server becomes unresponsive
   - Other connections starved of resources
   - Eventually crashes or kernel kills process

### WITH Backpressure (current implementation)

With the default 64KB high / 16KB low watermarks:

1. **Bounded Memory**: RSS stays relatively constant per connection
   - Each connection uses at most ~64KB write buffer
   - 50 connections ≈ 3.2MB write buffers (not 500MB+)
   - Memory scales linearly with connection count, not data volume

2. **Smooth Throughput**: Data flows at client's pace
   - `$send->()` awaits when buffer is full
   - Natural flow control matches client receive rate
   - No bufferbloat or stalls

3. **Fair Scheduling**: All connections get fair bandwidth
   - Fast clients drain quickly, slow clients throttled
   - Server remains responsive under load

4. **Latency Characteristics**:
   - Time-to-first-byte: fast (headers sent immediately)
   - Body transfer: paced by client receive rate
   - No long stalls followed by bursts

## Detecting Regressions

### Memory Regression Test

```bash
# Start server
PAGI_BACKPRESSURE_TEST=1 pagi-server --app examples/backpressure-test/app.pl &
SERVER_PID=$!

# Record baseline memory
BASELINE=$(ps -o rss= -p $SERVER_PID)

# Run slow client load (throttled to 100KB/s each)
for i in {1..20}; do
    curl --limit-rate 100K -o /dev/null http://localhost:5000/stream/50 &
done

# Wait a bit for connections to establish
sleep 5

# Check memory growth
LOADED=$(ps -o rss= -p $SERVER_PID)
GROWTH=$((LOADED - BASELINE))

echo "Baseline: ${BASELINE}KB, Under load: ${LOADED}KB, Growth: ${GROWTH}KB"

# Kill background curls
pkill -f "curl.*localhost:5000"

# Expected: Growth should be < 5MB for 20 connections
# Regression: Growth > 50MB indicates backpressure failure
if [ $GROWTH -gt 51200 ]; then
    echo "REGRESSION: Memory growth too high!"
    exit 1
fi

kill $SERVER_PID
```

### Throughput Regression Test

```bash
# With backpressure, throughput should be limited by client, not server
# This test ensures the server doesn't buffer excessively

# Start server
PAGI_BACKPRESSURE_TEST=1 pagi-server --app examples/backpressure-test/app.pl &
sleep 1

# Time a throttled download (should take ~50 seconds for 50MB at 1MB/s)
START=$(date +%s)
curl --limit-rate 1M -o /dev/null http://localhost:5000/stream/50
END=$(date +%s)
DURATION=$((END - START))

echo "Duration: ${DURATION}s (expected: ~50s)"

# If duration is much less than 50s, server buffered too much
# If duration is much more, something else is wrong
if [ $DURATION -lt 40 ]; then
    echo "WARNING: Transfer too fast - possible buffering issue"
fi
```

## Configuration Options

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PAGI_BACKPRESSURE_TEST` | 0 | Set to 1 to enable /stream endpoints |
| `PAGI_CHUNK_SIZE` | 4096 | Bytes per chunk (4KB) |
| `PAGI_STREAM_MB` | 10 | Default megabytes for /stream |

### Server Options

| Option | Default | Description |
|--------|---------|-------------|
| `--write-high-watermark` | 65536 | Pause sending above this (64KB) |
| `--write-low-watermark` | 16384 | Resume sending below this (16KB) |

### Testing Different Watermark Configurations

```bash
# Default (64KB/16KB) - matches Python asyncio
PAGI_BACKPRESSURE_TEST=1 pagi-server --app examples/backpressure-test/app.pl

# Large buffers (better throughput, more memory per connection)
PAGI_BACKPRESSURE_TEST=1 pagi-server --app examples/backpressure-test/app.pl \
    --write-high-watermark 262144 --write-low-watermark 65536

# Small buffers (lower memory, more context switches)
PAGI_BACKPRESSURE_TEST=1 pagi-server --app examples/backpressure-test/app.pl \
    --write-high-watermark 16384 --write-low-watermark 4096

# Stress test: disable backpressure (DON'T DO THIS IN PRODUCTION)
# This would require code changes - the watermarks just control thresholds
```

## Interpreting Results

### Good Results (Backpressure Working)

```
# Memory stays bounded under load
$ watch ps -o rss -p $PID
  RSS
12340    # baseline
14520    # 10 connections
16800    # 20 connections  (linear growth ~200KB/conn)
18900    # 30 connections

# Throughput matches client rate
$ curl --limit-rate 1M -o /dev/null -w "%{speed_download}\n" .../stream/10
1048576  # ~1MB/s as expected
```

### Bad Results (Regression)

```
# Memory grows unboundedly
$ watch ps -o rss -p $PID
  RSS
12340    # baseline
52340    # 10 connections (40MB growth!)
152340   # 20 connections (keeps growing)
# Eventually OOM

# Throughput faster than client rate (buffering)
$ curl --limit-rate 1M -o /dev/null -w "%{speed_download}\n" .../stream/10
5242880  # 5MB/s - server buffered everything, then client downloaded buffer
```
