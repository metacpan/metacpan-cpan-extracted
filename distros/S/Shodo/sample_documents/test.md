## POST /endpoint

get_entries

### Request

```json
POST /endpoint

{
   "params" : {
      "page" : 1,
      "category" : "technology",
      "limit" : 1
   },
   "jsonrpc" : "2.0",
   "method" : "get_entries",
   "id" : 1
}

```

### Parameters

* `page` - Page number you want to get.
  * isa: **Int**
  * default: **1**
  * optional: **1**
* `category` - Category of articles.
  * isa: **Str**
* `limit` - Limitation numbers per page.
  * isa: **Int**
  * default: **20**
  * optional: **1**

### Response

```json
Status: 200

{
   "jsonrpc" : "2.0",
   "id" : 1,
   "result" : {
      "entries" : [
         {
            "body" : "This is an example.",
            "title" : "Hello"
         }
      ]
   }
}

```

---

