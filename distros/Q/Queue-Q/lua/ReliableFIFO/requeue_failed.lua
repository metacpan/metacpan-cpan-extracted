-- requeue_failed: requeue a given number of failed items
-- # KEYS[1] from queue name (failed queue)
-- # KEYS[2] dest queue name (main queue)
-- # ARGV[1] timestamp
-- # ARGV[2] number of items to requeue. Value "0" means "all items"
--
if #KEYS ~= 2 then error('requeue_failed requires 2 keys') end
-- redis.log(redis.LOG_NOTICE, "nr keys: " .. #KEYS)
local from  = assert(KEYS[1], 'failed queue name missing')
local dest  = assert(KEYS[2], 'dest queue name missing')
local ts    = assert(tonumber(ARGV[1]), 'timestamp missing')
local num   = assert(tonumber(ARGV[2]), 'number of items missing')
local n     = 0;

if num == 0 then
    num = redis.call('llen', from)
end

for i = 1, num do
    local item = redis.call('rpop', from);
    if item == nil then break end

    local i = cjson.decode(item)

    if i.t_created == nil then
        i.t_created = i.t
    end
    i.t = ts

    local v = cjson.encode(i)
    redis.call('lpush', dest, v)

    n = n + 1
end
return n
