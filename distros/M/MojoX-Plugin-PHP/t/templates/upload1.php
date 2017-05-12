<html>
<head>
<title>file upload test</title>
</head>
<body>
<form enctype="multipart/form-data" action="/vars.php" method="POST">
    <input type="hidden" name="MAX_FILE_SIZE" value="100000" />
    Choose a file to upload: <input name="uploadedfile" type="file" /><br />
    <input type="submit" value="Upload File" />      
</form>
</body>
</html>
